extends WFCMultithreadedSolver

class_name WFCMultithreadedSolver2D

class WFCMultithreadedSolver2DSettings extends Resource:
	@export
	var max_threads: int = 2

	@export
	var extra_overlap: Vector2i = Vector2i(0, 0)

var settings: WFCMultithreadedSolver2DSettings = WFCMultithreadedSolver2DSettings.new()


func _split_range(first: int, size: int, partitions: int, min_partition_size: int) -> PackedInt64Array:
	assert(partitions > 0)

	@warning_ignore("integer_division")
	var approx_partition_size: int = size / partitions

	if approx_partition_size < min_partition_size:
		return _split_range(first, size, partitions - 1, min_partition_size)

	var res: PackedInt64Array = []

	for partition in range(partitions):
		@warning_ignore("integer_division")
		res.append((size * partition) / partitions)

	res.append(first + size)

	return res


func split_problem(problem_: WFCProblem) -> Array[Phase]:
	assert(problem_ is WFC2DProblem)
	assert(settings.extra_overlap.x >= 0)
	assert(settings.extra_overlap.y >= 0)

	var problem: WFC2DProblem = (problem_ as WFC2DProblem)

	var full_rect: Rect2i = problem.rect
	
	var rects: Array[Rect2i] = []
	
	var overlap_min: Vector2i = problem.get_dependencies_range() / 2
	var overlap_max: Vector2i = overlap_min + problem.get_dependencies_range() % 2

	var extra_overlap_min: Vector2i = settings.extra_overlap / 2
	var extra_overlap_max: Vector2i = extra_overlap_min + settings.extra_overlap % 2

	if full_rect.size.x > full_rect.size.y:
		var partitions = _split_range(
			full_rect.position.x,
			full_rect.size.x,
			settings.max_threads * 2,
			problem.get_dependencies_range().x + settings.extra_overlap.x
		)
		
		for i in range(partitions.size() - 1):
			rects.append(Rect2i(
				partitions[i],
				full_rect.position.x,
				partitions[i + 1] - partitions[i],
				full_rect.size.y
			))
	else:
		var partitions = _split_range(
			full_rect.position.y,
			full_rect.size.y,
			settings.max_threads * 2,
			problem.get_dependencies_range().y + settings.extra_overlap.y
		)

		for i in range(partitions.size() - 1):
			rects.append(Rect2i(
				full_rect.position.x,
				partitions[i],
				full_rect.size.x,
				partitions[i + 1] - partitions[i]
			))
	
	var res: Array[Phase] = []

	for r in [range(0, rects.size(), 2), range(1, rects.size(), 2)]:
		var problems: Array[WFCProblem] = []
		for i in r:
			var renderable_rect: Rect2i = rects[i] \
				.grow_individual(overlap_min.x, overlap_min.y, overlap_max.x, overlap_max.y) \
				.intersection(full_rect)
			
			var rect: Rect2i = renderable_rect \
				.grow_individual(
					extra_overlap_min.x, extra_overlap_min.y,
					extra_overlap_max.x, extra_overlap_max.y
				) \
				.intersection(full_rect)
			
			#print('subproblem for ', rect, ' renderable at ', renderable_rect)

			var sub_problem: WFC2DProblem = WFC2DProblem.new(
				problem.rules,
				problem.map,
				rect
			)

			sub_problem.renderable_rect = renderable_rect

			problems.append(sub_problem)
		res.append(Phase.new(problems))

	return res


func task_completed(task: Task):
	assert(task.problem is WFC2DProblem)

	var problem: WFC2DProblem = (task.problem as WFC2DProblem)

	problem.render_state_to_map(task.solver.current_state)

func render_intermediate_solutions():
	assert(is_running())
	
	for task in running_tasks:
		var state: WFCSolverState = task.solver.current_state
		
		if state == null:
			continue

		(task.problem as WFC2DProblem).render_state_to_map(state)





