extends RefCounted

class_name WFCSingleThreadSolverRunner


var interrupted: bool = false

var solver_settings: WFCSolver.WFCSolverSettings = WFCSolver.WFCSolverSettings.new()

var thread: Thread = null
var solver: WFCSolver = null

func is_started() -> bool:
	return solver != null

func is_running() -> bool:
	return thread != null

func interrupt():
	interrupted = true
	thread.wait_to_finish()
	thread = null


func _run_solver(solver: WFCSolver):
	while not interrupted and not solver.solve_step():
		pass

func start(problem: WFCProblem):
	assert(not is_started())

	solver = WFCSolver.new(problem, solver_settings)
	thread = Thread.new()
	thread.start(_run_solver.bind(solver), 0)



func update():
	assert(is_running())
	
	if not thread.is_alive():
		thread = null
		#TODO






