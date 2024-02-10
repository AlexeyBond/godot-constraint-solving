class_name WFCSolver
## Solver that solves finite discrete
## [url=https://en.wikipedia.org/wiki/Constraint_satisfaction_problem]constraint satisfaction problems[/url].
## [br]
## This solver uses backtracking along with
## [url=https://en.wikipedia.org/wiki/AC-3_algorithm]AC-3[/url]-like constraint propagetion
## algorithm.
## [br]
## Despite [code]WFC[/code] prefix in the name, this solver is capable of solving wider range of
## problems than just wave function collapse.
## In fact, wave function collapse is a special case of that wider class of constraint satisfaction
## problems.
## Specifically, such problems are described by following properties:
## [ul]
## finite number of variables
## each variable may have one value from finite set of values
## [/ul]
## The solver assumes that there is a finite set of values and each variable may have any of those
## values. However a problem implementation may limit domains of some variables by implementing
## [method WFCProblem.populate_initial_state].
## [br]
## Since this addon is biased towards WFC, variables are usually named "cells" and values are
## sometimes called "tiles".
extends RefCounted

## Settings of this solver.
## [br]
## Settings determine if solver uses backtracking or just performs a quick and dirty solution
## and when solver is allowed to fallback from backtracking to quick and dirty solution method.
var settings: WFCSolverSettings

## The problem to be solved by this solver
var problem: WFCProblem

## [code]true[/code] iff backtracking is currently enabled.
## [br]
## Initially equivallent to [member WFCSolverSettings.allow_backtracking] of [member settings].
## May change from [code]true[/code] to [code]false[/code] if
## [member WFCSolverSettings.require_backtracking] of [member settings] is [code]false[/code].
var backtracking_enabled: bool

## Number of times this solver did backtrack.
## [br]
## Is used to limit backtracking attempts when [WFCSolverSettings.backtracking_limit] of
## [member settings] is set to a positive value.
var backtracking_count: int = 0

var ac4_enabled: bool
var ac4_constraints: Array[WFCProblem.AC4BinaryConstraint]

func _make_initial_state(num_cells: int, initial_domain: WFCBitSet) -> WFCSolverState:
	var state := WFCSolverState.new()

	state.cell_domains.resize(num_cells)
	state.cell_domains.fill(initial_domain)

	state.cell_solution_or_entropy.resize(num_cells)
	state.cell_solution_or_entropy.fill(-(initial_domain.count_set_bits() - 1))

	state.unsolved_cells = num_cells
	state.observations_count = 0

	return state

## Current state of the solver.
## [br]
## Will be [code]null[/code] if solution has failed.
var current_state: WFCSolverState

## Best state ever acheived by this solver.
## [br]
## Best state is a state with largest number of solved cells.
## [br]
## Matches [member current_state] when backtracking is not enabled.
var best_state: WFCSolverState


func _init(problem_: WFCProblem, settings_: WFCSolverSettings = WFCSolverSettings.new()):
	settings = settings_
	backtracking_enabled = settings.allow_backtracking

	if settings.is_sparse_history_enabled():
		assert(settings.sparse_history_interval > 1)

	problem = problem_
	ac4_enabled = (not settings.force_ac3) and problem.supports_ac4()

	current_state = _make_initial_state(
		problem.get_cell_count(),
		problem.get_default_domain()
	)
	best_state = current_state

	if ac4_enabled:
		ac4_constraints = problem.get_ac4_binary_constraints()

	problem.populate_initial_state(current_state)


func _propagate_constraints_ac3() -> bool:
	"""
	Returns:
		true iff solution has failed and backtracking should be performed
	"""
	assert(current_state != null)

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

func _propagete_constraints_ac4() -> bool:
	var state := current_state
	assert(state != null)

	state.ensure_ac4_state(problem, ac4_constraints)

	while true:
		var changed_cells := state.extract_changed_cells()
		if changed_cells.is_empty():
			return false

		for cell_id in changed_cells:
			var new_domain := state.cell_domains[cell_id]
			var prev_acknowledged_domain := state.ac4_acknowledged_domains[cell_id]

			# New domain must be a subset of previous domain
			assert(prev_acknowledged_domain.is_superset_of(new_domain))

			if new_domain.equals(prev_acknowledged_domain):
				continue

			state.ac4_acknowledged_domains[cell_id] = new_domain

			var delta := new_domain.xor(prev_acknowledged_domain).to_array()

			for constraint_id in range(ac4_constraints.size()):
				var constraint := ac4_constraints[constraint_id]
				var dependent_cell := constraint.get_dependent(cell_id)
				if dependent_cell < 0:
					continue

				var dependent_domain := state.cell_domains[dependent_cell]
				var dependent_domain_changed := false

				for this_removed in delta:
					for dependent_removed in constraint.get_allowed(this_removed):
						if state.decrement_ac4_counter(dependent_cell, constraint_id, dependent_removed):
							if dependent_domain.get_bit(dependent_removed):
								if not dependent_domain_changed:
									dependent_domain = dependent_domain.copy()
									dependent_domain_changed = true
								dependent_domain.set_bit(dependent_removed, false)

				if dependent_domain_changed:
					if dependent_domain.is_empty():
						if backtracking_enabled:
							return true
						assert(false) # TODO: Handle contradiction in non-backtracking mode

					state.set_domain(dependent_cell, dependent_domain)

	return false

func _propagate_constraints() -> bool:
	if ac4_enabled:
		return _propagete_constraints_ac4()
	else:
		return _propagate_constraints_ac3()

func _continue_without_backtracking():
	current_state = best_state
	backtracking_enabled = false
	# Backtracking is disabled, so we can free memory occupied by previous states as they will
	# not be used.
	current_state.unlink_from_previous()

func _try_backtrack() -> bool:
	if settings.backtracking_limit > 0 and backtracking_count > settings.backtracking_limit:
		print_debug(
			'Backtracking limit exceeded after ',
			backtracking_count,
			' attempt(s), restarting from best state without backtracking',
		)

		_continue_without_backtracking()

		return false

	current_state = current_state.backtrack(problem)

	if current_state == null:
		print_debug(
			'Backtracking failed completely after ',
			backtracking_count,
			' attempt(s)',
		)

		if not settings.require_backtracking:
			print_debug('Restarting from best state without backtracking')

			_continue_without_backtracking()
		else:
			print_debug('Backtracking is required but failed - terminating with failure')
			return true

	backtracking_count += 1

	return false

func _should_keep_previous_state(state: WFCSolverState) -> bool:
	if not backtracking_enabled:
		return false

	if not settings.is_sparse_history_enabled():
		return true

	if state.observations_count < settings.sparse_history_start:
		return true

	if (state.observations_count - settings.sparse_history_start) % settings.sparse_history_interval == 0:
		return true

	return false

## Perform one iteration of problem solution.
## [br]
## Returns [code]true[/code] iff solution is completed.
func solve_step() -> bool:
	assert(current_state != null)

	if current_state.is_all_solved():
		return true

	var backtrack: bool = _propagate_constraints()

	if backtrack:
		return _try_backtrack()

	if current_state.is_all_solved():
		return true
	elif current_state.unsolved_cells < best_state.unsolved_cells:
		best_state = current_state

	current_state.prepare_divergence()

	if _should_keep_previous_state(current_state):
		var next_state := current_state.diverge(problem)

		if next_state == null:
			return _try_backtrack()
		else:
			current_state = next_state
	else:
		current_state.diverge_in_place(problem)

	return false

## Solve [member problem].
## [br]
## Returns the final state containing full solution ([member current_state]).
## Will return [code]null[/code] if solution has failed and partial solution is not acceptable
## according to the settings (i.e. [member WFCSolverSettings.require_backtracking] in
## [member settings] is set to true).
func solve() -> WFCSolverState:
	while not solve_step():
		pass

	return current_state
