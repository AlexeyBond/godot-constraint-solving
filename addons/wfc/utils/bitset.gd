extends Resource
## Stores a set of integers between [code]0[/code] (inclusive) and [member size] (exclusive).
##
## The set is stored as few integers consisting of at least [member size] bits.
## Such representation makes some operations (like set union, intersection, symmetric difference)
## BLAZINGLY FAST as they are performed using one bitwise operation per each 64 bits.
## [br]
## Note: Some operations are named and described in terms of sets and some in terms of bits and
## bitwise operations.
class_name WFCBitSet

## Bits 0..63
@export
var data0: int

## Bits 64..127
@export
var data1: int

## Bits 128...
@export
var dataX: PackedInt64Array = PackedInt64Array()

## Max. integer that can be stored in this set.
@export
var size: int = 0

const BITS_PER_INT = 64
const MAX_INT: int = 9223372036854775807
const ALL_SET: int = ~0

const STATIC_ELEMS: int = 2
const STATIC_BITS: int = BITS_PER_INT * STATIC_ELEMS

func _init(size_: int = 0, default: bool = false):
	if size_ == 0:
		return
	self.size = size_

	@warning_ignore("integer_division")
	var fullElems: int = size_ / BITS_PER_INT
	var lastElemBits: int = size_ % BITS_PER_INT

	var totalElems: int = fullElems

	if lastElemBits > 0:
		totalElems += 1

	if totalElems > STATIC_ELEMS:
		dataX.resize(totalElems - STATIC_ELEMS)

	if default:
		set_all()

func _n_bits_set(n: int) -> int:
	var res: int = 0

	for i in range(n):
		res |= 1 << i

	return res

## Set all used bits to [code]1[/code].
func set_all():
	@warning_ignore("integer_division")
	var fullElems: int = size / BITS_PER_INT
	var lastElemBits: int = size % BITS_PER_INT

	if fullElems == 0:
		data0 = _n_bits_set(lastElemBits)
		return
	else:
		data0 = ALL_SET
		fullElems -= 1

	if fullElems == 0:
		data1 = _n_bits_set(lastElemBits)
		return
	else:
		data1 = ALL_SET
		fullElems -= 1

	for i in range(fullElems):
		dataX.set(i, ALL_SET)

	dataX.set(fullElems, _n_bits_set(lastElemBits))

## Make a copy of this set.
func copy() -> WFCBitSet:
	var res : WFCBitSet = WFCBitSet.new(0)

	res.data0 = data0
	res.data1 = data1

	if size > STATIC_BITS:
		res.dataX = dataX.duplicate()

	res.size = size

	return res

## Compare this set with another one, returns [code]true[/code] if it is equal to this one.
## [br]
## Returns [code]false[/code] if sets contain same numbers but have different [member size].
func equals(other: WFCBitSet) -> bool:
	if other.size != size:
		return false

	if other.data0 != data0:
		return false

	if other.data1 != data1:
		return false

	for i in range(dataX.size()):
		if dataX[i] != other.dataX[i]:
			return false

	return true

## Add all members of [param other] set to this set.
func union_in_place(other: WFCBitSet):
	assert(other.size <= size)

	data0 |= other.data0
	data1 |= other.data1

	if size > STATIC_BITS:
		for i in range(other.dataX.size()):
			dataX.set(i, dataX[i] | other.dataX[i])

## Create a new [WFCBitSet] that contains all members contained in at least one of this and
## [param other] sets.
func union(other: WFCBitSet) -> WFCBitSet:
	if other.size > size:
		return other.union(self)

	var res: WFCBitSet = copy()
	res.union_in_place(other)
	return res

## Remove all members not contained in [param other] set from this set.
func intersect_in_place(other: WFCBitSet):
	assert(other.size >= size)

	data0 &= other.data0
	data1 &= other.data1

	if size > STATIC_BITS:
		for i in range(dataX.size()):
			dataX.set(i, dataX[i] & other.dataX[i])

## Create a new [WFCBitSet] that contains only members contained in both this and [param other]
## sets.
func intersect(other: WFCBitSet) -> WFCBitSet:
	if other.size < size:
		return other.intersect(self)

	var res: WFCBitSet = copy()
	res.intersect_in_place(other)
	return res

## Assigns this set to a [url=https://en.wikipedia.org/wiki/Symmetric_difference]symmetric
## difference[/url] of this set and [param other] set.
func xor_in_place(other: WFCBitSet):
	assert(other.size == size)

	data0 ^= other.data0
	data1 ^= other.data1

	if size > STATIC_BITS:
		for i in range(dataX.size()):
			dataX.set(i, dataX[i] ^ other.dataX[i])

func xor(other: WFCBitSet) -> WFCBitSet:
	assert(other.size == size)

	var res := copy()
	res.xor_in_place(other)

	return res

## Returns a new set that contains all elements between [code]0[/code] and [member size] that are
## not contained in this set.
func invert() -> WFCBitSet:
	var res: WFCBitSet = WFCBitSet.new(size, true)
	res.xor_in_place(self)
	return res

## Checks if this set is a superset of given other set (i.e. contains all elements of that set).
## [br]
## Equal sets are supersets of each other.
func is_superset_of(subset: WFCBitSet) -> bool:
	assert(size == subset.size)

	if data0 & subset.data0 != subset.data0:
		return false
	if data1 & subset.data1 != subset.data1:
		return false
	for i in range(dataX.size()):
		if dataX[i] & subset.dataX[i] != subset.dataX[i]:
			return false

	return true

## Reads a bit from this set.
## [br]
## In terms of sets, this funciton checks if given element is contained in this set.
func get_bit(bit_num: int) -> bool:
	if bit_num > size:
		return false

	if bit_num < STATIC_BITS:
		if bit_num < BITS_PER_INT:
			return data0 & (1 << bit_num)
		else:
			return data1 & (1 << (bit_num - BITS_PER_INT))
	else:
		bit_num -= STATIC_BITS

	@warning_ignore("integer_division")
	var el_num: int = bit_num / BITS_PER_INT
	var el_bit_num: int = bit_num % BITS_PER_INT

	return dataX[el_num] & (1 << el_bit_num)

## Writes a bit to this set.
## [br]
## In terms of sets, this function either idempotently removes (when [param value] is
## [code]false[/code]) or idempotently adds (when [param value] is [code]true[/code]) an element to
## this set.
func set_bit(bit_num: int, value: bool = true):
	assert(bit_num >= 0)
	assert(bit_num < size)

	if bit_num < STATIC_BITS:
		if bit_num < BITS_PER_INT:
			if value:
				data0 |= (1 << bit_num)
			else:
				data0 &= ~(1 << bit_num)
		else:
			if value:
				data1 |= (1 << (bit_num - BITS_PER_INT))
			else:
				data1 &= (1 << (bit_num - BITS_PER_INT))
		return
	else:
		bit_num -= STATIC_BITS

	@warning_ignore("integer_division")
	var el_index: int = bit_num / BITS_PER_INT
	var bit_index: int = bit_num % BITS_PER_INT

	if value:
		dataX.set(el_index, dataX[el_index] | (1 << bit_index))
	else:
		dataX.set(el_index, dataX[el_index] & ~(1 << bit_index))


func get_first_set_bit_index(bits: int) -> int:
	assert(bits != 0)

	if bits < 1:
		# Negative number => highest bit is set
		return BITS_PER_INT - 1

	var res: int = (BITS_PER_INT >> 1) - 1
	var step: int = BITS_PER_INT >> 2

	while true:
		var mask: int = 1 << res

		if (bits & mask) != 0:
			return res

		if mask < bits:
			res += step
		else:
			res -= step

		step = step >> 1
	return -1 # not reachable


func is_pot(x: int) -> bool:
	return (x & (x - 1)) == 0

## A value returned by [method get_only_set_bit] when the set contains more than one member.
const ONLY_BIT_MORE_BITS_SET = -2

## A value returned by [method get_only_set_bit] when the set contains no members.
const ONLY_BIT_NO_BITS_SET = -1

## If this set contains only one member, return it.
## [br]
## [constant ONLY_BIT_NO_BITS_SET] is returned when the set is empty.
## [constant ONLY_BIT_MORE_BITS_SET] is returned when this set contains more than one member.
func get_only_set_bit() -> int:
	var elem_index: int = -1

	if data0 != 0:
		if not is_pot(data0):
			return ONLY_BIT_MORE_BITS_SET
		elem_index = 0

	if data1 != 0:
		if elem_index >= 0 or not is_pot(data1):
			return ONLY_BIT_MORE_BITS_SET
		elem_index = 1

	if size > STATIC_BITS:
		for i in range(dataX.size()):
			var el: int = dataX[i]

			if el != 0:
				if elem_index >= 0 or not is_pot(el):
					return ONLY_BIT_MORE_BITS_SET
				elem_index = i + STATIC_ELEMS

	if elem_index < 0:
		return ONLY_BIT_NO_BITS_SET

	return get_first_set_bit_index(get_elem(elem_index)) + elem_index * BITS_PER_INT

## Checks if this set is empty.
func is_empty() -> bool:
	if data0 != 0 or data1 != 0:
		return false

	if size > STATIC_BITS:
		for d in dataX:
			if d != 0:
				return false

	return true

## Checks if this set has any common members with [param other] set.
func intersects_with(other: WFCBitSet) -> bool:
	if ((data0 & other.data0) != 0) || ((data1 & other.data1) != 0):
		return true

	for i in range(min(dataX.size(), other.dataX.size())):
		if (dataX[i] & other.dataX[i]) != 0:
			return true

	return false

## Returns [param n]'th integer used to store bits.
func get_elem(n: int) -> int:
	match n:
		0:
			return data0
		1:
			return data1
		_:
			return dataX[n - STATIC_ELEMS]

## Iterator over members of a [WFCBitSet].
class BitSetIterator:
	var bs: WFCBitSet
	var bit_index: int
	var arr_index: int
	var cur_elem: int

	func _init(bs_: WFCBitSet):
		bs = bs_

	func _iter_init(arg) -> bool:
		if bs.size == 0:
			return false

		bit_index = -1
		arr_index = 0
		cur_elem = bs.data0
		return _iter_next(arg)

	func _iter_next(_arg) -> bool:
		bit_index += 1

		while true:
			if cur_elem == 0:
				arr_index += 1
				if arr_index * BITS_PER_INT >= bs.size:
					return false

				cur_elem = bs.get_elem(arr_index)
				bit_index = 0
				continue
			var b: int = 1 << bit_index

			if cur_elem & b:
				cur_elem &= ~b
				return true

			bit_index += 1

		return false # unreachable

	func _iter_get(_arg):
		return bit_index + arr_index * BITS_PER_INT

## Creates an iterator over members of this set.
## [br]
## It may be more efficient when the set should be iterated only once.
## If the set will be iterated multiple times, creating temporary array using [method to_array] may
## be a better option.
func iterator() -> BitSetIterator:
	return BitSetIterator.new(self)

## Converts this set to array of it's members.
func to_array() -> PackedInt64Array:
	var res: PackedInt64Array = PackedInt64Array()

	for b in iterator():
		res.append(b)

	return res

func _count_bits(value: int, initial: int, pass_if_more_than: int) -> int:
	var res: int = initial

	while value != 0:
		value ^= (1 << get_first_set_bit_index(value))

		res += 1

		if res > pass_if_more_than:
			return res

	return res

## Returns number of members contained in this set.
func count_set_bits(pass_if_more_than: int = MAX_INT) -> int:
	var res: int = _count_bits(data0, 0, pass_if_more_than)

	if size > BITS_PER_INT and res <= pass_if_more_than:
		res = _count_bits(data1, res, pass_if_more_than)

		if size > STATIC_BITS and res <= pass_if_more_than:
			for i in range(dataX.size()):
				res = _count_bits(dataX[i], res, pass_if_more_than)

	return res

## Format this set as a bit-vector.
## [br]
## Output looks like
## [codeblock]
## "(1, 0, 1, 1, 0)"
## [/codeblock]
func format_bits() -> String:
	var res: String = '('

	for i in range(size):
		if get_bit(i):
			res += '1, '
		else:
			res += '0, '

	res += ')'

	return res
