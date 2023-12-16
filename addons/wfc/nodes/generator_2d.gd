class_name WFC2DGenerator
## Generates content of a map (TileMap or GridMap) using WFC algorithm.
extends Node

## A map that will be filled using WFC algorithm.
@export_node_path("TileMap", "GridMap")
var target: NodePath

## Rect of a map that will be filled.
## [br]
## Interpretation of this rect may depend on [WFCMapper2D] used.
## E.g. [WFCGridMapMapper2D] may use different planes with different offsets.
@export
var rect: Rect2i

## Rules that will be used.
## [br]
## If not specified, default rules will be created.
@export
@export_category("Rules")
var rules: WFCRules2D = WFCRules2D.new()

## A sample map to learn rules from.
@export_node_path("TileMap", "GridMap")
var positive_sample: NodePath

## A negative samples map.
@export_node_path("TileMap", "GridMap")
var negative_sample: NodePath

## Settings for a [WFCSolver].
@export
var solver_settings: WFCSolverSettings = WFCSolverSettings.new()

## What preconditions ([WFC2DPrecondition]) will be used.
## [br]
## If not set, a [WFC2DPreconditionReadExistingSettings] will be created and thus WFC will read
## existing tiles from [member target] map.
## If that's not necessary - set a [WFC2DPrecondition2DNullSettings] here.
@export
var precondition: WFC2DPrecondition2DNullSettings

## Settings for multithreaded solver runner.
## [br]
## Relevant iff [member use_multithreading] is [code]true[/code].
@export
@export_category("Runner")
var multithreaded_runner_settings: WFCMultithreadedRunnerSettings = WFCMultithreadedRunnerSettings.new()

## Settings for main thread solver runner.
## [br]
## Relevant iff [member use_multithreading] is [code]false[/code].
@export
var main_thread_runner_settings: WFCMainThreadRunnerSettings = WFCMainThreadRunnerSettings.new()

## If enabled, solver(s) will run on separate thread(s).
## Otherwise, there will be only one solver running on main thread, bit by bit every frame.
## [br]
## It's preferrable to use separate thread(s) in almost all cases.
## However, in some cases WFC may fail and/or produce invalid results when running in multiple
## threads.
## In such cases, it may make sense to still use multithreading but set
## [member WFCMultithreadedRunnerSettings.max_threads] in [member multithreaded_runner_settings] to
## [code]1[/code].
@export
var use_multithreading: bool = true

## If enabled, the generator will start WFC as soon as it is ready (i.e. literally in
## [method Node._ready]).
@export
@export_category("Behavior")
var start_on_ready: bool = false

## If enabled, current generation state will be rendered to [member target] map every frame while
## generation is in progress.
## [br]
## This is mostly useful for demos.
## In real game the map most likely won't be visible before it is generated completely, so updating
## it every frame is a waste of resources.
## [br]
## Even if this flag is disabled, generator [b]will[/b] render some intermediate results when
## running in multithreaded mode.
@export
var render_intermediate_results: bool = false

## If enabled, some debug information about rules will be printed to console.
@export
@export_category("Debug mode")
var print_rules: bool = false

## Emited when the generator starts generating map.
signal started

## Emitted when generation is completed.
signal done

var _runner: WFCSolverRunner = null

func _create_runner() -> WFCSolverRunner:
	if use_multithreading:
		var res: WFCMultithreadedSolverRunner = WFCMultithreadedSolverRunner.new()

		if multithreaded_runner_settings != null:
			res.runner_settings = multithreaded_runner_settings

		res.solver_settings = solver_settings
		return res
	else:
		var res: WFCMainThreadSolverRunner = WFCMainThreadSolverRunner.new()

		if main_thread_runner_settings != null:
			res.runner_settings = main_thread_runner_settings

		res.solver_settings = solver_settings
		return res

## Creates a mapper for given [param map] node.
## [br]
## Called when mapper is not provided in [member rules].
func _create_mapper(map: Node) -> WFCMapper2D:
	match map.get_class():
		"TileMap":
			return WFCLayeredTileMapMapper2D.new()
		"GridMap":
			return WFCGridMapMapper2D.new()
		var cname:
			push_error("Unsupported map type for WFC2DGenerator: " + cname)
			@warning_ignore("assert_always_false")
			assert(false)
			return null

func _create_precondition(problem_settings: WFC2DProblem.WFC2DProblemSettings, map: Node) -> WFC2DPrecondition:
	var settings: WFC2DPrecondition2DNullSettings = self.precondition

	if settings == null:
		settings = WFC2DPreconditionReadExistingSettings.new()

	var parameters: WFC2DPrecondition2DNullSettings.CreationParameters = WFC2DPrecondition2DNullSettings.CreationParameters.new()

	parameters.target_node = map
	parameters.problem_settings = problem_settings
	parameters.generator_node = self

	return settings.create_precondition(parameters)

func _create_problem(
	settings: WFC2DProblem.WFC2DProblemSettings,
	map: Node,
	precondition: WFC2DPrecondition
) -> WFC2DProblem:
	return WFC2DProblem.new(settings, map, precondition)

func _exit_tree():
	if _runner != null:
		_runner.interrupt()
		_runner = null

## Starts generation.
## [br]
## Should be called at most once.
## [br]
## Should not be called manually when [member start_on_ready] is [code]true[/code].
func start():
	assert(_runner == null)
	assert(target != null)
	assert(rect.has_area())

	var target_node: Node = get_node(target)
	assert(target_node != null)

	if not rules.is_ready():
		assert(positive_sample != null)

		var positive_sample_node: Node = get_node(positive_sample)
		assert(positive_sample_node != null)

		if rules == null:
			rules = WFCRules2D.new()
		else:
			rules = rules.duplicate(false) as WFCRules2D

			assert(rules != null)

		if rules.mapper == null:
			rules.mapper = _create_mapper(target_node)
		if not rules.mapper.is_ready():
			rules.mapper.learn_from(positive_sample_node)
		rules.learn_from(positive_sample_node)

		if rules.complete_matrices and negative_sample != null and not negative_sample.is_empty():
			var negative_sample_node: Node = get_node(negative_sample)

			if negative_sample_node != null:
				rules.learn_negative_from(negative_sample_node)

		if print_rules and OS.is_debug_build():
			print_debug('Rules learned:\n', rules.format())

			print_debug('Influence range: ', rules.get_influence_range())

	var problem_settings: WFC2DProblem.WFC2DProblemSettings = WFC2DProblem.WFC2DProblemSettings.new()

	problem_settings.rules = rules
	problem_settings.rect = rect

	var precondition: WFC2DPrecondition = _create_precondition(problem_settings, target_node)

	started.emit()

	# TODO: Call this in separate thread if long-running generators will be used to generate preconditions
	precondition.prepare()

	var problem: WFC2DProblem = _create_problem(problem_settings, target_node, precondition)

	_runner = _create_runner()

	_runner.start(problem)

	_runner.all_solved.connect(func(): done.emit())
	_runner.sub_problem_solved.connect(_on_solved)
	_runner.partial_solution.connect(_on_partial_solution)

func _on_solved(problem: WFC2DProblem, state: WFCSolverState):
	if state != null:
		problem.render_state_to_map(state)

func _on_partial_solution(problem: WFC2DProblem, state: WFCSolverState):
	if not render_intermediate_results:
		return

	_on_solved(problem, state)

func _ready():
	if start_on_ready:
		start()

func _process(_delta):
	if _runner != null and _runner.is_running():
		_runner.update()

## Returns generation progress.
## [br]
## Returned value is in range between [code]0.0[/code] and [code]1.0[/code] (both inclusive).
## Just like in [method WFCSolverRunner.get_progress].
## [br]
## Returns [code]0.0[/code] if generation was not yet started.
func get_progress() -> float:
	if _runner == null:
		return 0

	return _runner.get_progress()

## Returns [code]true[/code] iff any solver is currently running.
func is_running() -> bool:
	if _runner == null:
		return false

	return _runner.is_running()

## Resets this generator to it's initial state.
## [br]
## Stops any running solver(s), if any.
func reset():
	if _runner != null:
		if _runner.is_running():
			_runner.interrupt()
		_runner = null
