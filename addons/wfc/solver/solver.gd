class_name WFCSolver

extends RefCounted

var backtracking_enabled: bool
var settings: WFCSolverSettings

var backtracking_count: int = 0

func _make_initial_state(num_cells: int, initial_domain: WFCBitSet) -> WFCSolverState:
	var state = WFCSolverState.new()

	state.cell_domains.resize(num_cells)
	state.cell_domains.fill(initial_domain)
	
	state.cell_solution_or_entropy.resize(num_cells)
	state.cell_solution_or_entropy.fill(-(initial_domain.count_set_bits() - 1))

	state.unsolved_cells = num_cells

	return state

var current_state: WFCSolverState
var best_state: WFCSolverState

var problem: WFCProblem


func _init(problem_: WFCProblem, settings_: WFCSolverSettings = WFCSolverSettings.new()):
	settings = settings_
	backtracking_enabled = settings.allow_backtracking

	problem = problem_
	current_state = _make_initial_state(
		problem.get_cell_count(),
		problem.get_default_domain()
	)
	best_state = current_state

	problem.populate_initial_state(current_state)


func _propagate_constraints() -> bool:
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
			var should_backtrack: bool = current_state.set_domain(
				related_cell_id,
				problem.compute_cell_domain(
					current_state, related_cell_id
				)
			)

			if should_backtrack and backtracking_enabled:
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

	if current_state.is_all_solved():
		return true
	
	var backtrack: bool = _propagate_constraints()

	if backtrack:
		if settings.backtracking_limit > 0 and backtracking_count > settings.backtracking_limit:
			print_debug('Backtracking limit exceeded, restarting from best state without backtracking')
			
			current_state = best_state
			backtracking_enabled = false
			
			return false

		backtracking_count += 1
		
		current_state = current_state.backtrack()

		if current_state == null:
			print_debug('Backtracking failed')

			if not settings.require_backtracking:
				print_debug('Restarting from best state without backtracking')

				current_state = best_state
				backtracking_enabled = false

		return false

	if current_state.is_all_solved():
		return true
	elif current_state.unsolved_cells < best_state.unsolved_cells:
		best_state = current_state

	current_state.prepare_divergence()

	if backtracking_enabled:
		current_state = current_state.diverge()
	else:
		current_state.diverge_in_place()

	return false

func solve() -> WFCSolverState:
	while not solve_step():
		pass

	return current_state






