class_name WFCMainThreadSolverRunner
## A [code]WFCSolverRunner[/code] that runs a single solver in main thread.
##
## In most cases, it's preferrable to use [WFCMultithreadedSolverRunner] with
## [member WFCMultithreadedRunnerSettings.max_threads] of [code]1[/code] instead.
extends WFCSolverRunner

## Settings of this solver.
var runner_settings: WFCMainThreadRunnerSettings = WFCMainThreadRunnerSettings.new()

var problem: WFCProblem = null
var solver: WFCSolver = null

var interrupted: bool = false

## See [member WFCSolverRunner.start].
func start(problem_: WFCProblem):
	assert(not is_started())

	problem = problem_
	solver = WFCSolver.new(problem, solver_settings)

## See [member WFCSolverRunner.update].
## [br]
## In this implementation it calls [member WFCSolver.solve_step] few times.
func update():
	assert(is_running())

	var start_ticks: int = Time.get_ticks_msec()

	while solver.current_state != null and not solver.current_state.is_all_solved():
		solver.solve_step()

		if solver.current_state == null or solver.current_state.is_all_solved():
			sub_problem_solved.emit(problem, solver.current_state)
			all_solved.emit()
			return

		if (Time.get_ticks_msec() - start_ticks) >= runner_settings.max_ms_per_frame:
			break

	partial_solution.emit(problem, solver.current_state)

## See [member WFCSolverRunner.is_running].
func is_running() -> bool:
	return is_started() and (not interrupted) and solver.current_state != null and not solver.current_state.is_all_solved()

## See [member WFCSolverRunner.is_started].
func is_started() -> bool:
	return solver != null

## See [member WFCSolverRunner.interrupt].
func interrupt():
	assert(is_started())

	interrupted = true

## See [member WFCSolverRunner.get_progress].
func get_progress() -> float:
	if not is_started():
		return 0.0

	if not is_running():
		return 1.0

	return 1.0 - (float(solver.current_state.unsolved_cells) / float(problem.get_cell_count()))
