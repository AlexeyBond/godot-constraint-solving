class_name WFCMainThreadSolverRunner

extends WFCSolverRunner

var runner_settings: WFCMainThreadRunnerSettings = WFCMainThreadRunnerSettings.new()

var problem: WFCProblem = null
var solver: WFCSolver = null

var interrupted: bool = false

func start(problem_: WFCProblem):
	assert(not is_started())

	problem = problem_
	solver = WFCSolver.new(problem, solver_settings)

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

func is_running() -> bool:
	return is_started() and (not interrupted) and solver.current_state != null and not solver.current_state.is_all_solved()

func is_started() -> bool:
	return solver != null

func interrupt():
	assert(is_started())

	interrupted = true

func get_progress() -> float:
	if not is_started():
		return 0.0
	
	if not is_running():
		return 1.0
	
	return 1.0 - (float(solver.current_state.unsolved_cells) / float(problem.get_cell_count()))
