extends RefCounted

class_name WFCMultithreadedSolver

const _NO_REAL_MULTITHREADING = false

class Phase extends RefCounted:
	var problems: Array[WFCProblem]
	
	func _init(problems_: Array[WFCProblem]):
		problems = problems_

class Task extends RefCounted:
	var problem: WFCProblem
	var solver: WFCSolver
	var thread: Thread
	var completed: bool
	
	func _init(problem_: WFCProblem, solver_: WFCSolver, thread_: Thread):
		problem = problem_
		solver = solver_
		thread = thread_
		completed = false

func split_problem(_problem: WFCProblem) -> Array[Phase]:
	@warning_ignore("assert_always_false")
	assert(false)
	return []


func task_completed(_task: Task):
	pass


var phases: Array[Phase]

var current_phase: int = -1

var interrupted: bool = false

var running_tasks: Array[Task]

var solver_settings: WFCSolver.WFCSolverSettings = WFCSolver.WFCSolverSettings.new()

func is_started() -> bool:
	return current_phase >= 0

func is_running() -> bool:
	return not (running_tasks.is_empty() or interrupted)

func interrupt():
	interrupted = true

	for task in running_tasks:
		task.thread.wait_to_finish()

func _run_solver(solver: WFCSolver):
	while (not interrupted) and (not solver.solve_step()):
		pass

func _noop():
	pass

func _start_phase(phase: Phase):
	for problem in phase.problems:
		var solver: WFCSolver = WFCSolver.new(problem, solver_settings)
		var thread: Thread = Thread.new()

		if _NO_REAL_MULTITHREADING:
			_run_solver(solver)
			thread.start(_noop)
		else:
			thread.start(_run_solver.bind(solver))

		var task: Task = Task.new(problem, solver, thread)

		running_tasks.append(task)

func start(problem: WFCProblem):
	assert(not is_started())
	assert(not is_running())
	assert(phases.is_empty())

	phases = split_problem(problem)

	assert(not phases.is_empty())

	_start_phase(phases[0])
	current_phase = 0

signal partial_solution(problem: WFCProblem, solver_state: WFCSolverState)
signal problem_solved(problem: WFCProblem, solver_state: WFCSolverState)

func update():
	assert(is_started())
	assert(is_running())

	var alive_tasks: int = 0

	for task in running_tasks:
		if task.thread.is_alive():
			alive_tasks += 1

			var state: WFCSolverState = task.solver.current_state

			if state != null:
				partial_solution.emit(task.problem, state)
		elif not task.completed:
			task.thread.wait_to_finish()
			task.completed = true
			task_completed(task)
			problem_solved.emit(task.problem, task.solver.current_state)


	if alive_tasks == 0:
		running_tasks.clear()
	
		current_phase += 1
		
		if current_phase < phases.size():
			_start_phase(phases[current_phase])







