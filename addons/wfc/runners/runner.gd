extends RefCounted
## Abstract base class for objects responsible for creating and running [WFCSolver]s.
##
## There are two concrete subclasses: [WFCMainThreadSolverRunner] and
## [WFCMultithreadedSolverRunner].
## It's not likely that any other subclasses may be useful.
class_name WFCSolverRunner

## Settings for [WFCSolver](s) that will be created by this runner.
var solver_settings: WFCSolverSettings = WFCSolverSettings.new()

## Starts solving given problem.
## [br]
## Must be called at most once per [WFCSolverRunner] instance.
func start(_problem: WFCProblem):
	assert(false)

## Updates state of this runner.
## [br]
## Must be called periodically, usually every frame in [method Node._process] of some node like [WFC2DGenerator].
func update():
	assert(false)

## Returns [code]true[/code] iff this runner was started and is has not finished.
func is_running() -> bool:
	assert(false)
	return false

## Returns [code]true[/code] iff this runner was started.
func is_started() -> bool:
	assert(false)
	return false

## Stops the runner without waiting for full solution of the problem.
func interrupt():
	assert(false)

## Returns estimated solution progress.
## [br]
## Returned value is usually close to number of solved cells divided by total number of cells.
## Returned value may decrease when solver backtracks.
## [br]
## Do not use this method to check if the runner is started or finished.
## Use [method is_running], [method is_started] and [signal all_solved] instead.
func get_progress() -> float:
	assert(false)
	return 0.0

## Emitted when current state of one of solvers changes.
## [br]
## It is not emitted on every change but once for every active solver on every [method update] call.
signal partial_solution(problem: WFCProblem, solver_state: WFCSolverState)

## Emitted when one of sub-problems is fully solved.
signal sub_problem_solved(problem: WFCProblem, solver_state: WFCSolverState)

## Emitted when the problem is solved completely.
signal all_solved
