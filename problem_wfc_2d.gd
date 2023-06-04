extends WFCProblem

class_name WFC2DProblem

var rules: WFCRules2D
var map: Node
var rect: Rect2i

var renderable_rect: Rect2i

var axes: Array[Vector2i] = []
var axis_matrices: Array[BitMatrix] = []

func _init(
	rules_: WFCRules2D,
	map_: Node,
	rect_: Rect2i,
):
	assert(rules_.mapper != null)
	assert(rules_.mapper.supports_map(map_))
	assert(rules_.mapper.size() > 0)
	assert(rect_.has_area())

	rules = rules_
	map = map_
	rect = rect_
	renderable_rect = rect_

	for i in range(rules.axes.size()):
		axes.append(rules.axes[i])
		axis_matrices.append(rules.axis_matrices[i])

		axes.append(-rules.axes[i])
		axis_matrices.append(rules.axis_matrices[i].transpose())

func coord_to_id(coord: Vector2i) -> int:
	return rect.size.x * coord.y + coord.x

func id_to_coord(id: int) -> Vector2i:
	var szx: int = rect.size.x
	@warning_ignore("integer_division")
	return Vector2i(id % szx, id / szx)

func get_cell_count() -> int:
	return rect.get_area()

func get_default_constraints() -> BitSet:
	return BitSet.new(rules.mapper.size(), true)

func populate_initial_state(state: WFCSolverState):
	var mapper: Mapper2D = rules.mapper

	for x in range(rect.size.x):
		for y in range(rect.size.y):
			var pos: Vector2i = Vector2i(x, y)
			var cell: int = mapper.read_cell(map, pos + rect.position)
			
			if cell >= 0:
				state.set_solution(coord_to_id(pos), cell)

func compute_cell_constraints(state: WFCSolverState, cell_id: int) -> BitSet:
	var res: BitSet = state.cell_constraints[cell_id].copy()
	var pos: Vector2i = id_to_coord(cell_id)
	
	for i in range(axes.size()):
		var other_pos: Vector2i = pos + axes[i]
		
		if not rect.has_point(other_pos + rect.position):
			continue
		
		var other_id: int = coord_to_id(other_pos)
		
		if state.cell_solution_or_entropy[other_id] == WFCSolverState.CELL_SOLUTION_FAILED:
			continue

		var other_constraint: BitSet = state.cell_constraints[other_id]
		res.intersect_in_place(axis_matrices[i].transform(other_constraint))
		
		#print('\ttransform: ', other_constraint.format_bits(), ' -> ', axis_matrices[i].transform(other_constraint).format_bits())
	
	#print(state.cell_constraints[cell_id].format_bits(), ' -> ', res.format_bits())
	
	return res


func mark_related_cells(changed_cell_id: int, mark_cell: Callable):
	var pos: Vector2i = id_to_coord(changed_cell_id)
	
	for i in range(axes.size()):
		var other_pos: Vector2i = pos + axes[i]
		if rect.has_point(other_pos + rect.position):
			mark_cell.call(coord_to_id(other_pos))

func render_state_to_map(state: WFCSolverState):
	assert(rect.encloses(renderable_rect))
	var mapper: Mapper2D = rules.mapper
	
	var render_rect_offset = renderable_rect.position - rect.position

	for x in range(renderable_rect.size.x):
		for y in range(renderable_rect.size.y):
			var local_coord: Vector2i = Vector2i(x, y) + render_rect_offset
			var cell: int = state.cell_solution_or_entropy[coord_to_id(local_coord)]
			
			if cell == WFCSolverState.CELL_SOLUTION_FAILED:
				cell = -1

			mapper.write_cell(
				map,
				local_coord + rect.position,
				cell
			)


func get_dependencies_range() -> Vector2i:
	var rx: int = 0
	var ry: int = 0
	
	for a in axes:
		rx = max(rx, abs(a.x))
		ry = max(ry, abs(a.y))
	
	return Vector2i(rx, ry)









