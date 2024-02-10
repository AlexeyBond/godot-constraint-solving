extends WFCSolverRunner
## A [code]WFCSolverRunner[/code] that tries to split the problem into multiple sub-problem and runs
## them on different threads when possible.
##
## When a problem cannot be split it just runs a single solver on a separate [Thread].
class_name WFCMultithreadedSolverRunner

# Runs solvers in main thread instead of [Thread]s.
# Useful for problem split debugging.
const _STUB_NO_MULTITHREADING = false

## Settings for this runner.
var runner_settings: WFCMultithreadedRunnerSettings = WFCMultithreadedRunnerSettings.new()

class _TaskStatusContainer extends RefCounted:
	var unsolved_cells: int

	var state_snapshot_required: bool
	var state_snapshot_mutex: Mutex
	var state_snapshot: WFCSolverState

	func _init(total_cells: int):
		unsolved_cells = total_cells
		state_snapshot_mutex = Mutex.new()

	func take_and_request_snapshot() -> WFCSolverState:
		state_snapshot_mutex.lock()
		var snapshot := state_snapshot
		state_snapshot_mutex.unlock()
		state_snapshot_required = true
		return snapshot

class _Task extends RefCounted:
	var problem: WFCProblem
	var dependencies: PackedInt64Array
	var solver: WFCSolver = null
	var thread: Thread = null
	var is_completed: bool = false
	var status_container: _TaskStatusContainer

	func _init(problem_: WFCProblem, dependencies_: PackedInt64Array):
		problem = problem_
		dependencies = dependencies_
		status_container = _TaskStatusContainer.new(problem.get_cell_count())

	func is_started() -> bool:
		return thread != null

	func is_running() -> bool:
		return thread != null and not is_completed

	func check_just_completed() -> bool:
		if is_completed:
			return false

		if thread.is_alive():
			return false

		is_completed = true

		return true

	func is_blocked(tasks: Array[_Task]) -> bool:
		for dep_index in dependencies:
			if not tasks[dep_index].is_completed:
				return true

		return false

	func ensure_stopped():
		if thread != null:
			thread.wait_to_finish()

	func get_total_cells() -> int:
		return problem.get_cell_count()

	func get_unsolved_cells() -> int:
		return status_container.unsolved_cells

var tasks: Array[_Task] = []
var interrupted: bool = false

func _thread_main(solver: WFCSolver, status_container: _TaskStatusContainer):
	while (not interrupted) and (not solver.solve_step()):
		status_container.unsolved_cells = solver.current_state.unsolved_cells

		if status_container.state_snapshot_required:
			status_container.state_snapshot_required = false

			var state_snapshot: WFCSolverState = solver.current_state.make_snapshot()

			var mx := status_container.state_snapshot_mutex
			mx.lock()
			status_container.state_snapshot = state_snapshot
			mx.unlock()

	solver.current_state.unlink_from_previous()
	solver.best_state.unlink_from_previous()

func _noop():
	pass

func _start_tasks(max_start: int) -> int:
	var started: int = 0
	for task in tasks:
		if (not task.is_started()) and (not task.is_blocked(tasks)):
			task.solver = WFCSolver.new(task.problem, solver_settings)
			task.thread = Thread.new()
			if _STUB_NO_MULTITHREADING:
				task.thread.start(_noop)
				task.solver.solve()
			else:
				task.thread.start(_thread_main.bind(task.solver, task.status_container))

			started += 1

			if started >= max_start:
				break

	return started

## See [method WFCSolverRunner.start].
func start(problem: WFCProblem):
	assert(not is_started())

	for sub_problem in problem.split(runner_settings.get_max_threads()):
		tasks.append(
			_Task.new(sub_problem.problem, sub_problem.dependencies)
		)

	var started: int = _start_tasks(runner_settings.get_max_threads())

	assert(started > 0)

## See [method WFCSolverRunner.update].
func update():
	var unstarted: int = 0
	var running: int = 0
	var completed: int = 0

	var emit_partial_solution := partial_solution.get_connections().size() > 0

	for task in tasks:
		if task.is_completed:
			completed += 1
		elif not task.is_started():
			unstarted += 1
		elif task.check_just_completed():
			task.thread.wait_to_finish()
			sub_problem_solved.emit(task.problem, task.solver.current_state)
			completed += 1
		else:
			if emit_partial_solution:
				var snapshot := task.status_container.take_and_request_snapshot()
				if snapshot != null:
					partial_solution.emit(task.problem, snapshot)
			running += 1

	if unstarted == 0 and running == 0:
		all_solved.emit()
		return

	if running < runner_settings.get_max_threads():
		var started: int = _start_tasks(runner_settings.get_max_threads() - running)

		assert(running > 0 or started > 0)

## See [method WFCSolverRunner.is_running].
func is_running() -> bool:
	if interrupted:
		return false

	var running_tasks: int = 0

	for task in tasks:
		if task.is_running():
			running_tasks += 1

	return running_tasks > 0

## See [method WFCSolverRunner.is_started].
func is_started() -> bool:
	return not tasks.is_empty()

## See [method WFCSolverRunner.interrupt].
func interrupt():
	interrupted = true

	for task in tasks:
		task.ensure_stopped()

## See [method WFCSolverRunner.get_progress].
func get_progress() -> float:
	var total: int = 0
	var unsolved: int = 0

	for task in tasks:
		total += task.get_total_cells()
		unsolved += task.get_unsolved_cells()

	return 1.0 - (float(unsolved) / float(total))




