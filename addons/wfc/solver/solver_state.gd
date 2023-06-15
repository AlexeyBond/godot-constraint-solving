class_name WFCSolverState

extends RefCounted

const MAX_INT: int = 9223372036854775807

const CELL_SOLUTION_FAILED: int = MAX_INT

var previous: WFCSolverState = null
var cell_domains: Array[WFCBitSet]

"""
i'th element of cell_solution_or_entropy contains eighter:
	- a negated "entropy" value, -(number_of_options - 1) if there are multiple options
		for the i'th cell. Value is always negative in this case.
		Note: it's not a real entropy value: log(number_of_options) would be closer to
			the real entropy.
	- a non-negative value equal to chosen cell type number
	- CELL_SOLUTION_FAILED if cell type could not be chosen for i'th cell
		(possible only if backtracking is disabled)
"""
var cell_solution_or_entropy: PackedInt64Array
var unsolved_cells: int

var changed_cells: PackedInt64Array

var divergence_cell: int = -1
var divergence_options: Array[int]

var divergence_candidates: Dictionary = {}

func is_cell_solved(cell_id: int) -> bool:
	return cell_solution_or_entropy[cell_id] >= 0

func get_cell_solution(cell_id: int) -> int:
	assert(is_cell_solved(cell_id))
	return cell_solution_or_entropy[cell_id]

func is_all_solved() -> bool:
	return unsolved_cells == 0

func _store_solution(cell_id: int, solution: int):
	assert(not is_cell_solved(cell_id))
	assert(solution >= 0)

	cell_solution_or_entropy[cell_id] = solution
	unsolved_cells -= 1
	
	divergence_candidates.erase(cell_id)

func set_solution(cell_id: int, solution: int):
	var bs: WFCBitSet = WFCBitSet.new(cell_domains[0].size)
	bs.set_bit(solution, true)
	set_domain(cell_id, bs, 0)

func set_domain(cell_id: int, domain: WFCBitSet, entropy: int = -1) -> bool:
	var should_backtrack: bool = false

	if cell_domains[cell_id].equals(domain):
		return should_backtrack

	changed_cells.append(cell_id)

	var only_bit: int = domain.get_only_set_bit()

	if only_bit == WFCBitSet.ONLY_BIT_NO_BITS_SET:
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

func backtrack() -> WFCSolverState:
	if previous == null:
		return null

	var state: WFCSolverState = previous.diverge()

	if state != null:
		return state

	return previous.backtrack()

func make_next() -> WFCSolverState:
	var new: WFCSolverState = WFCSolverState.new()

	new.cell_domains = cell_domains.duplicate()
	new.cell_solution_or_entropy = cell_solution_or_entropy.duplicate()
	new.unsolved_cells = unsolved_cells
	new.divergence_candidates = divergence_candidates.duplicate()

	new.previous = self

	return new

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

	divergence_options.shuffle()

func diverge() -> WFCSolverState:
	assert(divergence_cell >= 0)

	if divergence_options.is_empty():
		return null

	var next_state: WFCSolverState = make_next()

	next_state.set_solution(divergence_cell, divergence_options.pop_back())

	return next_state

func diverge_in_place():
	assert(divergence_cell >= 0)
	assert(divergence_options.size() > 0)
	
	set_solution(divergence_cell, divergence_options[0])
	
	divergence_options.clear()
	divergence_cell = -1










