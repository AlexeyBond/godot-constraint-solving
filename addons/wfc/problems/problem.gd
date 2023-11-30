class_name WFCProblem

extends RefCounted

func get_cell_count() -> int:
	@warning_ignore("assert_always_false")
	assert(false)
	return -1

func get_default_domain() -> WFCBitSet:
	@warning_ignore("assert_always_false")
	assert(false)
	return WFCBitSet.new(0)

func populate_initial_state(_state: WFCSolverState):
	pass

func compute_cell_domain(_state: WFCSolverState, _cell_id: int) -> WFCBitSet:
	@warning_ignore("assert_always_false")
	assert(false)
	return WFCBitSet.new(0)

func mark_related_cells(_changed_cell_id: int, _mark_cell: Callable):
	@warning_ignore("assert_always_false")
	assert(false)


class SubProblem extends RefCounted:
	var problem: WFCProblem

	# Indexes (in array returned by the same call of split()) of sub-problems this one depends on.
	var dependencies: PackedInt64Array

	func _init(problem_: WFCProblem, dependencies_: PackedInt64Array):
		problem = problem_
		dependencies = dependencies_


func split(_concurrency_limit: int) -> Array[SubProblem]:
	"""
	Split this problem into few smaller problems that can be solved concurrently.

	By default (if not overridden by WFCProblem subclass) just returns a single
	sub-problem, equivallent to whole this problem.
	"""
	return [SubProblem.new(self, [])]

func pick_divergence_option(options: Array[int]) -> int:
	"""
	Chose a tile to ve observed in certain cell.

	`options` parameter contains array of all allowed tiles.
	The chosen option should be removed from the array.

	By default picks a random element.
	Can be customized to take probabilities into account.
	"""
	assert(options.size() > 0)
	return options.pop_at(randi_range(0, options.size() - 1))
