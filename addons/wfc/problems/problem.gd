class_name WFCProblem
## Base class for classes representing problems solvable by [WFCSolver].
extends RefCounted

class AC4BinaryConstraint extends RefCounted:
	func get_dependent(cell_id: int) -> int:
		@warning_ignore("assert_always_false")
		assert(false)
		return -1

	func get_dependency(cell_id: int) -> int:
		@warning_ignore("assert_always_false")
		assert(false)
		return -1

	func get_allowed(dependency_variant: int) -> PackedInt64Array:
		@warning_ignore("assert_always_false")
		assert(false)
		return []

## Returns number of cells (variables) this problem contains.
func get_cell_count() -> int:
	@warning_ignore("assert_always_false")
	assert(false)
	return -1

## Returns default domain (set of allowed values) of a cell/variable.
## [br]
## It usually is a [WFCBitSet] of certain size filled with [code]1[/code]s.
func get_default_domain() -> WFCBitSet:
	@warning_ignore("assert_always_false")
	assert(false)
	return WFCBitSet.new(0)

## This method will be called by solver once, before starting solution process.
## [br]
## A [WFCProblem] may limit initial domains of some cells here.
func populate_initial_state(_state: WFCSolverState):
	pass

## Computes a domain of given cell.
## [br]
## Usually called by solver when some of cells, [param _cell_id] depends on has changed.
func compute_cell_domain(_state: WFCSolverState, _cell_id: int) -> WFCBitSet:
	@warning_ignore("assert_always_false")
	assert(false)
	return WFCBitSet.new(0)

## Called by solver when domain of cell [param _changed_cell_id] has changed.
## The [WFCProblem] should mark all cells that depend on the changed cell by calling
## [param _mark_cell] with ids of those cells (one call with single parameter per cell).
func mark_related_cells(_changed_cell_id: int, _mark_cell: Callable):
	@warning_ignore("assert_always_false")
	assert(false)

## Represents a part of [WFCProblem] as returned by [method WFCProblem.split].
class SubProblem extends RefCounted:
	## The partial problem itself.
	var problem: WFCProblem

	## Indexes (in array returned by the same call of [method WFCProblem.split]) of sub-problems
	## this one depends on.
	var dependencies: PackedInt64Array

	func _init(problem_: WFCProblem, dependencies_: PackedInt64Array):
		problem = problem_
		dependencies = dependencies_

## Split this problem into few smaller problems that can be solved concurrently.
## [br]
## By default (if not overridden by WFCProblem subclass) just returns a single sub-problem,
## equivallent to whole this problem.
## [br]
## This method is used by [WFCMultithreadedSolverRunner] to distribute work across multiple threads.
func split(_concurrency_limit: int) -> Array[SubProblem]:
	return [SubProblem.new(self, [])]

## Chose a tile to be observed in some cell.
## [br]
## [param options] contains array of all allowed tiles.
## The chosen option should be removed from the array.
## [br]
## By default picks a random element.
## Can be customized to take probabilities into account.
func pick_divergence_option(options: Array[int]) -> int:
	assert(options.size() > 0)
	return options.pop_at(randi_range(0, options.size() - 1))

func supports_ac4() -> bool:
	return false

func get_ac4_binary_constraints() -> Array[AC4BinaryConstraint]:
	@warning_ignore("assert_always_false")
	assert(false)
	return []
