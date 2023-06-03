class_name WFCSolver

extends RefCounted

@export var allow_backtracking = true

func _make_initial_state(num_cells: int, initial_constraints: BitSet) -> WFCSolverState:
	var state = WFCSolverState.new()

	state.cell_constraints.resize(num_cells)
	state.cell_constraints.fill(initial_constraints)
	
	state.cell_solution_or_entropy.resize(num_cells)
	state.cell_solution_or_entropy.fill(-(initial_constraints.count_set_bits() - 1))

	state.unsolved_cells = num_cells

	return state

var current_state: WFCSolverState
var problem: WFCProblem


func _init(problem_: WFCProblem):
	problem = problem_
	current_state = _make_initial_state(
		problem.get_cell_count(),
		problem.get_default_constraints()
	)
	problem.populate_initial_state(current_state)


func _solve_constraints() -> bool:
	"""
	Returns:
		true iff solution has failed and backtracking should be performed
	"""
	while true:
		var changed: PackedInt64Array = current_state.extract_changed_cells()
		
		if changed.is_empty():
			return false

		var related: Dictionary = {}

		var mark_related: Callable = func(cell_id: int):
			if current_state.is_cell_solved(cell_id):
				return

			related[cell_id] = true

		for cell_id in changed:
			problem.mark_related_cells(cell_id, mark_related)

		for related_cell_id in related.keys():
			var should_backtrack: bool = current_state.set_constraints(
				related_cell_id,
				problem.compute_cell_constraints(
					current_state, related_cell_id
				)
			)

			if should_backtrack and allow_backtracking:
				return true

	@warning_ignore("assert_always_false")
	assert(false) # unreachable
	return false

func solve_step() -> bool:
	"""
	Returns:
		true iff process has termitated (eighter successfully or with failure)
	"""
	assert(current_state != null)
	assert(not current_state.is_all_solved())

	if current_state.is_all_solved():
		return true
	
	var backtrack: bool = _solve_constraints()

	if backtrack:
		current_state = current_state.backtrack()
		return false
	
	if current_state.is_all_solved():
		return true

	current_state.prepare_divergence()

	if allow_backtracking:
		current_state = current_state.diverge()
	else:
		current_state.diverge_in_place()

	return false

func solve() -> WFCSolverState:
	while not solve_step():
		pass

	return current_state






