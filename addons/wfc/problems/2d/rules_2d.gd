extends Resource
## A 2D wave function collapse rules.
class_name WFCRules2D

## A mapper used to access the map.
@export
var mapper: WFCMapper2D

## If enabled, the rules will try to infer some additional allowed transitions when learning from
## sample.
## [br]
## This is done by calling [method WFCBitMatrix.complete] on each matrix in [member axis_matrices].
@export
var complete_matrices: bool = true

## Offsets from a cell to other cells that cell depends on.
## [br]
## By default it's [code](0,1)[/code] and [code](1,0)[/code], so each cell depends on it's
## neighbours along X and Y axes.
## However, one may want a cell to depend, for example, on it's diagonal neighbours.
## In such case one should add [code](1,1)[/code] and [code](1,-1)[/code] to this list.
## [br]
## Another (and, perhaps, more meaningful) use-case is a hexagonal grid.
## In case of hexagonal grid we want a cell to depend on neighbours in three directions, so third
## vector should be added.
## The exact vector depends on chosen coordinate system - for example, in case of [TileMap]s it is
## determined by [member TileSet.tile_layout].
## Note that this WFC implementation won't work with some layouts.
## [br]
## [b]Note:[/b] Any additional element in this array will have a significant impact on performance
## of the solver as it proportionally increases number of constraints.
## [br]
## [b]Note:[/b] This array should not include vectors opposite to other vectors contained here.
## E.g. if [code](1,0)[/code] is here then [code](-1,0)[/code] should not.
## In fact opposite vectors are incluged implicitly because all constraints are symmetric.
@export
var axes: Array[Vector2i] = [
	Vector2i(0, 1),
	Vector2i(1, 0)
]

## Matrices of allowed tile combinations along each axis.
## [br]
## [color=red]Do not modify manually[/color] unless you know precisely what you are doing.
@export
var axis_matrices: Array[WFCBitMatrix] = []

## Probabilities of all tile types.
## [br]
## [color=red]Do not modify manually[/color] unless you know precisely what you are doing.
## [br]
## Probabilties are filled automatically when rules are learned from sample and
## [member probabilities_enabled] is enabled.
@export
var probabilities: PackedFloat32Array = []

## Assumed domain of cells outside the area being generated.
## [br]
## [color=red]Do not modify manually[/color] unless you know precisely what you are doing.
@export
var edge_domain: WFCBitSet = null

## If enabled, the solver will take tile probabilities into account.
## When not - probabilities of all tiles are considered equal.
@export
var probabilities_enabled: bool = true

## Name of tile metadata property that marks tiles that are assumed to be placed outside of
## generated area.
@export
var edge_condition_meta_name: String = "wfc_edge"

func _learn_from(map: Node, positive: bool):
	var learning_rect: Rect2i = mapper.get_used_rect(map)

	for x in range(learning_rect.position.x, learning_rect.end.x):
		for y in range(learning_rect.position.y, learning_rect.end.y):
			var cell_coords: Vector2i = Vector2i(x, y)
			var cell: int = mapper.read_cell(map, cell_coords)

			if cell < 0:
				continue

			for a in range(axes.size()):
				var a_dir: Vector2i = axes[a]
				var other_cell: int = mapper.read_cell(
					map,
					cell_coords + a_dir,
				)
				if other_cell < 0:
					continue

				axis_matrices[a].set_bit(cell, other_cell, positive)

func _learn_probabilities():
	var size := mapper.size()
	probabilities.resize(size)
	for i in range(size):
		var probability := mapper.read_tile_probability(i)
		assert(probability > 0.0)
		probabilities[i] = probability

func _learn_edge_conditions():
	var size := mapper.size()
	var ed := WFCBitSet.new(size)
	for i in range(size):
		if mapper.read_tile_meta_boolean(i, edge_condition_meta_name):
			ed.set_bit(i)

	if not ed.is_empty():
		edge_domain = ed

## Learn rules from given sample map.
## [br]
## Also learns tile probabilities from [member mapper] (if [member probabilities_enabled] enabled
## and probabilities were not loaded before) and infers additional rules (if
## [member complete_matrices] is enabled).
func learn_from(map: Node):
	assert(mapper != null)
	assert(mapper.supports_map(map))
	assert(mapper.size() > 1)
	assert(axes.size() > 0)
	assert(axis_matrices.is_empty() or axis_matrices.size() == axes.size())

	if probabilities_enabled:
		if probabilities.is_empty():
			_learn_probabilities()
		else:
			assert(probabilities.size() == mapper.size())

	if axis_matrices.size() == 0:
		var num_cell_types: int = mapper.size()

		assert(num_cell_types > 1)

		for i in range(axes.size()):
			axis_matrices.append(WFCBitMatrix.new(num_cell_types, num_cell_types))

	_learn_from(map, true)

	if complete_matrices:
		for mat in axis_matrices:
			mat.complete()

	_learn_edge_conditions()

## Learns disallowed tile combinations from a sample map.
## [br]
## Useful mostly when [member complete_matrices] is enabled - to exclude some of inferred rules.
func learn_negative_from(map: Node):
	assert(mapper != null)
	assert(mapper.supports_map(map))
	assert(mapper.size() > 1)
	assert(axes.size() > 0)
	assert(axis_matrices.size() == axes.size())

	_learn_from(map, false)

## Returns [code]true[/code] if these rules are ready to be used.
## [br]
## In order to be ready the rules should have [member mapper], [member axis_matrices] and
## [member probabilities] (if enabled) set up.
func is_ready() -> bool:
	return mapper != null and \
		mapper.is_ready() and \
		axis_matrices.size() == axes.size() and \
		(probabilities.size() == mapper.size() or not probabilities_enabled)

## Prints rules to string.
func format() -> String:
	var res: String = ""

	for i in range(len(axes)):
		res += 'Axis ' + str(i) + ' (' + str(axes[i]) + '):\n'
		res += axis_matrices[i].format_bits()
		res += '\n'

	return res

const MAX_INT_32 = 2147483647

## Returns distances along X and Y axes at which a certain cell stops influencing domains of other
## cells along those axes.
## [br]
## Returned value will be equal to maximum allowed integer value if constraints of some cell types
## may propogate infinitely.
## E.g. if there are cell types [code]A[/code] and [code]B[/code] and the following combinations are
## only allowed along horizontal X axis:
## [codeblock]
## AA AB BB
## [/codeblock]
## cell with type [code]B[/code] wouldn't allow any cell types other than [code]B[/code] to the
## left, so all cells to the left must be of type [code]B[/code] and x component of vector returned
## by [method get_influence_range] will be [code]2147483647[/code].
## But if we also allow combination of [code]BA[/code], then any cell can be placed to the left of
## cell of type [code]B[/code], and x component of vector returned by [method get_influence_range]
## will become [code]1[/code].
## [br]
## This function is used to approximate real "influence range" of a cell - an area around a cell
## that can be influenced by (and symmetrically influence) it.
## However, it's just an approximation and it won't work wor some rule sets.
func get_influence_range() -> Vector2i:
	assert(axes.size() > 0)
	assert(axis_matrices.size() == axes.size())

	var res: Vector2i = Vector2i(0, 0)

	for a in range(len(axes)):
		var matrix: WFCBitMatrix = axis_matrices[a]
		var axis: Vector2i = axes[a]

		var forward_path: int = matrix.get_longest_path()

		if forward_path <= 0:
			if axis.x != 0:
				res.x = MAX_INT_32
			if axis.y != 0:
				res.y = MAX_INT_32
			continue

		var backward_path: int = matrix.transpose().get_longest_path()

		if backward_path <= 0:
			if axis.x != 0:
				res.x = MAX_INT_32
			if axis.y != 0:
				res.y = MAX_INT_32
			continue

		var longest_path: int = max(forward_path, backward_path)

		res.x = max(res.x, abs(axis.x) * longest_path)
		res.y = max(res.y, abs(axis.y) * longest_path)

	return res
