class_name WFCSolverState

extends RefCounted

const MAX_INT: int = 9223372036854775807

const CELL_SOLUTION_FAILED: int = MAX_INT

## Previous state to backtrack to.
var previous: WFCSolverState = null

## Current domains of all cells.
var cell_domains: Array[WFCBitSet]

"""
i'th element of cell_solution_or_entropy contains either:
	- a negated "entropy" value, -(number_of_options - 1) if there are multiple options
		for the i'th cell. Value is always negative in this case.
		Note: it's not a real entropy value: log(number_of_options) would be closer to
			the real entropy.
	- a non-negative value equal to chosen cell type number
	- CELL_SOLUTION_FAILED if cell type could not be chosen for i'th cell
		(possible only if backtracking is disabled)
"""
var cell_solution_or_entropy: PackedInt64Array

## Number of cells that still have domains of more than one value.
var unsolved_cells: int

## Number of "observations" made to reach this state.
## [br]
## This nubmer may be different from [code]len(cell_domains) - unsolved_cells[/code] since one
## observation may cause immediate collapse of other cells.
var observations_count: int

var changed_cells: PackedInt64Array

var divergence_cell: int = -1
var divergence_options: Array[int]

var divergence_candidates: Dictionary = {}

var ac4_counters: PackedInt32Array = []

## counter_index = Vector3i(cell_id, constraint_id, tile_id).dot(ac4_counter_index_coefficients)
var ac4_counter_index_coefficients: Vector3i
var ac4_acknowledged_domains: Array[WFCBitSet]

## Check if given cell has solution.
## [br]
## Returns [code]true[/code] also when solution for given cell is failed.
func is_cell_solved(cell_id: int) -> bool:
	return cell_solution_or_entropy[cell_id] >= 0

## Returns solution of given cell.
## [br]
## It is undefined behavior if there is no solution for given cell.
## [br]
## Returns [constant CELL_SOLUTION_FAILED] if solution for given cell is failed.
func get_cell_solution(cell_id: int) -> int:
	assert(is_cell_solved(cell_id))
	return cell_solution_or_entropy[cell_id]

## Returns [code]true[/code] iff all cells are solved or failed.
func is_all_solved() -> bool:
	return unsolved_cells == 0

func _store_solution(cell_id: int, solution: int):
	assert(not is_cell_solved(cell_id))
	assert(solution >= 0)

	cell_solution_or_entropy[cell_id] = solution
	unsolved_cells -= 1

	divergence_candidates.erase(cell_id)

## Set solution for given cell.
func set_solution(cell_id: int, solution: int):
	var bs: WFCBitSet = WFCBitSet.new(cell_domains[0].size)
	bs.set_bit(solution, true)
	set_domain(cell_id, bs, 0)

## Set domain of given cell.
## [br]
## When [param entropy] is set to positive value, it may be used instead of computing entropy
## from [param domain].
func set_domain(cell_id: int, domain: WFCBitSet, entropy: int = -1) -> bool:
	var should_backtrack: bool = false

	assert(cell_domains[cell_id].intersect(domain).equals(domain))

	if cell_domains[cell_id].equals(domain):
		return should_backtrack

	changed_cells.append(cell_id)

	var only_bit: int = domain.get_only_set_bit()

	if only_bit == WFCBitSet.ONLY_BIT_NO_BITS_SET:
		print_stack()
		_store_solution(cell_id, CELL_SOLUTION_FAILED)
		entropy = 0
		should_backtrack = true
	elif only_bit != WFCBitSet.ONLY_BIT_MORE_BITS_SET:
		_store_solution(cell_id, only_bit)
		entropy = 0
	else:
		if entropy < 0:
			entropy = domain.count_set_bits() - 1

		assert(entropy > 0)
		cell_solution_or_entropy[cell_id] = -entropy
		divergence_candidates[cell_id] = true

	cell_domains[cell_id] = domain

	return should_backtrack

func extract_changed_cells() -> PackedInt64Array:
	var res: PackedInt64Array = changed_cells.duplicate()
	changed_cells.clear()
	return res

func backtrack(problem: WFCProblem) -> WFCSolverState:
	if previous == null:
		return null

	var state: WFCSolverState = previous.diverge(problem)

	if state != null:
		return state

	return previous.backtrack(problem)

func make_next() -> WFCSolverState:
	var new: WFCSolverState = WFCSolverState.new()

	new.cell_domains = cell_domains.duplicate()
	new.cell_solution_or_entropy = cell_solution_or_entropy.duplicate()
	new.unsolved_cells = unsolved_cells
	new.divergence_candidates = divergence_candidates.duplicate()

	# AC4 state is transferred to next state, without copying.
	# And will be recovered in case of backtracking.
	# Otherwise, basic WFC demo could take dozens of gigabytes of RAM to store all state change
	# history.
	new.ac4_counters = ac4_counters
	ac4_counters = []
	new.ac4_counter_index_coefficients = ac4_counter_index_coefficients
	new.ac4_acknowledged_domains = ac4_acknowledged_domains
	ac4_acknowledged_domains = []

	new.observations_count = observations_count

	new.previous = self

	return new

## Makes a copy of this state.
## [br]
## The copy is unlinked from this state's previous state.
## The copy is safe to access from thread different from one the solver runs on.
func make_snapshot() -> WFCSolverState:
	var new: WFCSolverState = WFCSolverState.new()

	new.cell_domains = cell_domains.duplicate()
	new.cell_solution_or_entropy = cell_solution_or_entropy.duplicate()
	new.unsolved_cells = unsolved_cells

	return new

## Disconnect this state from previous one (if any).
## [br]
## This should be done when solution is completed in order to free memory occupied by previous
## states.
func unlink_from_previous():
	previous = null

func pick_divergence_cell() -> int:
	assert(unsolved_cells > 0)

	var options: Array[int] = []
	var target_entropy: int = MAX_INT

	var candidates = divergence_candidates.keys()

	if candidates.is_empty():
		candidates = range(cell_solution_or_entropy.size())

	for i in candidates:
		var entropy: int = - cell_solution_or_entropy[i]

		if entropy <= 0:
			continue

		if entropy == target_entropy:
			options.append(i)
		elif entropy < target_entropy:
			options.clear()
			options.append(i)
			target_entropy = entropy

	assert(options.size() > 0)

	return options.pick_random()

func prepare_divergence():
	divergence_cell = pick_divergence_cell()
	divergence_candidates.erase(divergence_cell)
	divergence_options.clear()

	for option in cell_domains[divergence_cell].iterator():
		divergence_options.append(option)

func diverge(problem: WFCProblem) -> WFCSolverState:
	assert(divergence_cell >= 0)

	if divergence_options.is_empty():
		return null

	var next_state: WFCSolverState = make_next()

	var solution := problem.pick_divergence_option(divergence_options)

	next_state.set_solution(divergence_cell, solution)
	next_state.observations_count += 1

	return next_state

func diverge_in_place(problem: WFCProblem):
	assert(divergence_cell >= 0)
	assert(divergence_options.size() > 0)

	var solution := problem.pick_divergence_option(divergence_options)

	set_solution(divergence_cell, solution)

	divergence_options.clear()
	divergence_cell = -1
	observations_count += 1

func get_ac4_counter_offset(cell_id: int, constraint_id: int, tile_id: int) -> int:
	var t := ac4_counter_index_coefficients * Vector3i(cell_id, constraint_id, tile_id)
	return t.x + t.y + t.z # :facepalm: no .dot() for integer vectors

func decrement_ac4_counter(cell_id: int, constraint_id: int, tile_id: int) -> bool:
	var index := get_ac4_counter_offset(cell_id, constraint_id, tile_id)
	var value := ac4_counters[index]
	#assert(value > 0)
	value -= 1
	ac4_counters[index] = value

	return value == 0

func ensure_ac4_state(problem: WFCProblem, binary_constraints: Array[WFCProblem.AC4BinaryConstraint]):
	if ac4_counters.size() > 0:
		return

	var total_cells := problem.get_cell_count()
	var default_domain := problem.get_default_domain()
	var domain_size := default_domain.size
	var total_constraints := binary_constraints.size()

	ac4_acknowledged_domains = []
	ac4_acknowledged_domains.resize(total_cells)
	ac4_acknowledged_domains.fill(default_domain)

	ac4_counters = []
	var counters_size := total_cells * total_constraints * domain_size
	ac4_counters.resize(counters_size)
	ac4_counter_index_coefficients = Vector3i(
		total_constraints * domain_size,
		domain_size,
		1
	)

	for constraint_id in range(binary_constraints.size()):
		var constraint := binary_constraints[constraint_id]
		var initial_constraint_counters: PackedInt64Array = []
		initial_constraint_counters.resize(domain_size)
		for tile in default_domain.iterator():
			for allowed_tile in constraint.get_allowed(tile):
				initial_constraint_counters[allowed_tile] += 1
		for cell_id in range(total_cells):
			for tile_id in range(default_domain.size):
				ac4_counters[get_ac4_counter_offset(cell_id, constraint_id, tile_id)] =\
					initial_constraint_counters[tile_id]

	changed_cells.clear()
	for cell_id in range(cell_domains.size()):
		if not default_domain.equals(cell_domains[cell_id]):
			for constraint in binary_constraints:
				if not is_cell_solved(constraint.get_dependent(cell_id)):
					changed_cells.append(cell_id)
					break
