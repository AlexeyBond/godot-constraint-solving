extends RefCounted

class_name WFCSolverRunner

var solver_settings: WFCSolverSettings = WFCSolverSettings.new()

func start(_problem: WFCProblem):
	assert(false)

func update():
	assert(false)

func is_running() -> bool:
	assert(false)
	return false

func is_started() -> bool:
	assert(false)
	return false

func interrupt():
	assert(false)

func get_progress() -> float:
	assert(false)
	return 0.0

signal partial_solution(problem: WFCProblem, solver_state: WFCSolverState)
signal sub_problem_solved(problem: WFCProblem, solver_state: WFCSolverState)
signal all_solved
