extends WFCProblem

class_name WFC2DProblem

class WFC2DProblemSettings extends Resource:
	@export
	var rules: WFCRules2D

	@export
	var rect: Rect2i

var rules: WFCRules2D
var map: Node
var rect: Rect2i

var renderable_rect: Rect2i

var axes: Array[Vector2i] = []
var axis_matrices: Array[BitMatrix] = []

func _init(settings: WFC2DProblemSettings, map_: Node):
	assert(settings.rules.mapper != null)
	assert(settings.rules.mapper.supports_map(map_))
	assert(settings.rules.mapper.size() > 0)
	assert(settings.rect.has_area())

	map = map_
	rules = settings.rules
	rect = settings.rect
	renderable_rect = settings.rect

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

func _split_range(first: int, size: int, partitions: int, min_partition_size: int) -> PackedInt64Array:
	assert(partitions > 0)

	@warning_ignore("integer_division")
	var approx_partition_size: int = size / partitions

	if approx_partition_size < min_partition_size:
		return _split_range(first, size, partitions - 1, min_partition_size)

	var res: PackedInt64Array = []

	for partition in range(partitions):
		@warning_ignore("integer_division")
		res.append((size * partition) / partitions)

	res.append(first + size)

	return res

func split(concurrency_limit: int) -> Array[SubProblem]:
	if concurrency_limit < 2:
		return super.split(concurrency_limit)
	
	var rects: Array[Rect2i] = []
	
	var dependency_range: Vector2i = get_dependencies_range()
	var overlap_min: Vector2i = dependency_range / 2
	var overlap_max: Vector2i = overlap_min + dependency_range % 2

	var influence_range: Vector2i = rules.get_influence_range()

	if rect.size.x > rect.size.y:
		var partitions: PackedInt64Array = _split_range(
			rect.position.x,
			rect.size.x,
			concurrency_limit * 2,
			dependency_range.x + influence_range.x * 2
		)

		for i in range(partitions.size() - 1):
			rects.append(Rect2i(
				partitions[i],
				rect.position.x,
				partitions[i + 1] - partitions[i],
				rect.size.y
			))
	else:
		var partitions: PackedInt64Array = _split_range(
			rect.position.y,
			rect.size.y,
			concurrency_limit * 2,
			dependency_range.y + influence_range.y * 2
		)

		for i in range(partitions.size() - 1):
			rects.append(Rect2i(
				rect.position.x,
				partitions[i],
				rect.size.x,
				partitions[i + 1] - partitions[i]
			))

	if rects.size() < 3:
		return super.split(concurrency_limit)

	var res: Array[SubProblem] = []

	for i in range(rects.size()):
		var sub_renderable_rect: Rect2i = rects[i] \
			.grow_individual(overlap_min.x, overlap_min.y, overlap_max.x, overlap_max.y) \
			.intersection(rect)
		
		var sub_rect: Rect2i = sub_renderable_rect

		if (i & 1) == 0:
			sub_rect = sub_rect \
				.grow_individual(
					influence_range.x, influence_range.y,
					influence_range.x, influence_range.y
				) \
				.intersection(rect)

		var sub_settings: WFC2DProblemSettings = WFC2DProblemSettings.new()
		sub_settings.rules = rules
		sub_settings.rect = sub_rect

		var sub_problem: WFC2DProblem = WFC2DProblem.new(sub_settings, map)
		sub_problem.renderable_rect = sub_renderable_rect
		
		var dependencies: PackedInt64Array = []

		if (i & 1) == 1:
			if i > 0:
				dependencies.append(i - 1)
			
			if i < (rects.size() - 1):
				dependencies.append(i + 1)

		res.append(SubProblem.new(sub_problem, dependencies))

	return res








