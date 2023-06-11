extends Resource

class_name WFCRules2D

@export
var mapper: WFCMapper2D

@export
var complete_matrices: bool = true

@export
var axes: Array[Vector2i] = [
	Vector2i(0, 1),
	Vector2i(1, 0)
]

@export
var axis_matrices: Array[WFCBitMatrix] = []


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

func learn_from(map: Node):
	assert(mapper != null)
	assert(mapper.supports_map(map))
	assert(mapper.size() > 1)
	assert(axes.size() > 0)
	assert(axis_matrices.is_empty() or axis_matrices.size() == axes.size())

	if axis_matrices.size() == 0:
		var num_cell_types: int = mapper.size()

		assert(num_cell_types > 1)

		for i in range(axes.size()):
			axis_matrices.append(WFCBitMatrix.new(num_cell_types, num_cell_types))

	_learn_from(map, true)

	if complete_matrices:
		for mat in axis_matrices:
			mat.complete()


func learn_negative_from(map: Node):
	assert(mapper != null)
	assert(mapper.supports_map(map))
	assert(mapper.size() > 1)
	assert(axes.size() > 0)
	assert(axis_matrices.size() == axes.size())
	
	_learn_from(map, false)


func is_ready() -> bool:
	return mapper != null and mapper.is_ready() and axis_matrices.size() == axes.size()


func format() -> String:
	var res: String = ""

	for i in range(len(axes)):
		res += 'Axis ' + str(i) + ' (' + str(axes[i]) + '):\n'
		res += axis_matrices[i].format_bits()
		res += '\n'

	return res

const MAX_INT_32 = 2147483647

func get_influence_range() -> Vector2i:
	"""
	Returns distances along X and Y axes at wiich a certain cell stops
	influencing domains of other cells along those axes.

	Returned value will be equal to maximum allowed integer value if constraints
	of some cell types may propogate infinitely.
	E.g. if there are cell types 0 and 1 and the following combinations are
	only allowed along horizontal X axis:
		00 01 11
	cell with type 1 wouldn't allow any cell types other than 1 to the left,
	so all cells to the left must be of type 1 and x component of vector
	returned by get_influence_range() will be 2147483647.
	But if we also allow combination of 10, then any cell can be place to the
	left of cell of type 1, and x component of vector returned by
	get_influence_range() will be 1.
	"""
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


















