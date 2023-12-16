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

func _make_initial_state(num_cells: int, initial_domain: WFCBitSet) -> WFCSolverState:
	var state := WFCSolverState.new()

	state.cell_domains.resize(num_cells)
	state.cell_domains.fill(initial_domain)

	state.cell_solution_or_entropy.resize(num_cells)
	state.cell_solution_or_entropy.fill(-(initial_domain.count_set_bits() - 1))

	state.unsolved_cells = num_cells

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

func _try_backtrack() -> bool:
	if settings.backtracking_limit > 0 and backtracking_count > settings.backtracking_limit:
		print_debug(
			'Backtracking limit exceeded after ',
			backtracking_count,
			' attempt(s), restarting from best state without backtracking',
		)

		current_state = best_state
		backtracking_enabled = false

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

			current_state = best_state
			backtracking_enabled = false
		else:
			print_debug('Backtracking is required but failed - terminating with failure')
			return true

	backtracking_count += 1

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

	if backtracking_enabled:
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
