class_name WFCSudokuProblem

extends WFCProblem

var width: int
var height: int
var numbers: int

func _init(w: int = 9, h: int = 9, numbers_: int = 9):
	assert(numbers_ > 0)
	assert(w > 0 and w <= numbers_)
	assert(h > 0 and h <= numbers_)

	width = w
	height = h
	numbers = numbers_

func id_to_coords(cell_id: int) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(
		cell_id % width,
		cell_id / width,
	)

func coords_to_id(x: int, y: int) -> int:
	return width * y + x

func get_cell_count() -> int:
	return width * height

func get_default_domain() -> WFCBitSet:
	return WFCBitSet.new(numbers, true)

func populate_initial_state(_state: WFCSolverState):
	pass

func compute_cell_domain(state: WFCSolverState, cell_id: int) -> WFCBitSet:
	var coords: Vector2i = id_to_coords(cell_id)
	var domain: WFCBitSet = state.cell_domains[cell_id].copy()

	for i in range(width):
		var c: int = coords_to_id(i, coords.y)
		if c != cell_id and state.is_cell_solved(c):
			domain.set_bit(
				state.get_cell_solution(c),
				false,
			)

	for i in range(height):
		var c: int = coords_to_id(coords.x, i)
		if c != cell_id and state.is_cell_solved(c):
			domain.set_bit(
				state.get_cell_solution(c),
				false,
			)

	return domain

func mark_related_cells(changed_cell_id: int, mark_cell: Callable):
	var coords: Vector2i = id_to_coords(changed_cell_id)

	for i in range(width):
		if i != coords.x:
			mark_cell.call(coords_to_id(i, coords.y))
	for i in range(height):
		if i != coords.y:
			mark_cell.call(coords_to_id(coords.x, i))














