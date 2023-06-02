class_name WFCProblem

extends RefCounted

func get_cell_count() -> int:
	@warning_ignore("assert_always_false")
	assert(false)
	return -1

func get_default_constraints() -> BitSet:
	@warning_ignore("assert_always_false")
	assert(false)
	return BitSet.new(0)

func populate_initial_state(_state: WFCSolverState):
	pass

func compute_cell_constraints(_state: WFCSolverState, _cell_id: int) -> BitSet:
	@warning_ignore("assert_always_false")
	assert(false)
	return BitSet.new(0)

func mark_related_cells(_changed_cell_id: int, _mark_cell: Callable):
	@warning_ignore("assert_always_false")
	assert(false)
