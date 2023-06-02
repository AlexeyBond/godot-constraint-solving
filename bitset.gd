extends RefCounted

class_name BitSet

var data: PackedInt64Array = PackedInt64Array()
var size: int = 0

const BITS_PER_INT = 64
const MAX_INT: int = 9223372036854775807
const ALL_SET: int = ~0

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
	data.resize(totalElems)

	if default:
		set_all()

func set_all():
	@warning_ignore("integer_division")
	var fullElems: int = size / BITS_PER_INT
	var lastElemBits: int = size % BITS_PER_INT

	for i in range(fullElems):
		data.set(i, ALL_SET)
	
	var last: int = 0
	
	for i in range(lastElemBits):
		last |= 1 << i
	
	data.set(fullElems, last)


func duplicate() -> BitSet:
	var res : BitSet = BitSet.new(0)
	
	res.data = data.duplicate()
	res.size = size
	
	return res


func equals(other: BitSet) -> bool:
	if other.size != size:
		return false
	
	for i in range(data.size()):
		if data[i] != other.data[i]:
			return false
	
	return true


func union_in_place(other: BitSet):
	assert(other.size <= size)
	
	for i in range(other.data.size()):
		data.set(i, data[i] | other.data[i])

func union(other: BitSet) -> BitSet:
	if other.size > size:
		return other.union(self)
	
	var res: BitSet = duplicate()
	res.union_in_place(other)
	return res


func intersect_in_place(other: BitSet):
	assert(other.size >= size)
	
	for i in range(data.size()):
		data.set(i, data[i] & other.data[i])


func intersect(other: BitSet) -> BitSet:
	if other.size < size:
		return other.intersect(self)

	var res: BitSet = duplicate()
	res.intersect_in_place(other)
	return res

func get_bit(bit_num: int) -> bool:
	if bit_num > size:
		return false

	@warning_ignore("integer_division")
	var el_num: int = bit_num / BITS_PER_INT
	var el_bit_num: int = bit_num % BITS_PER_INT

	return data[el_num] & (1 << el_bit_num)


func set_bit(bit_num: int, value: bool = true):
	assert(bit_num >= 0)
	assert(bit_num < size)

	@warning_ignore("integer_division")
	var el_index: int = bit_num / BITS_PER_INT
	var bit_index: int = bit_num % BITS_PER_INT
	
	if value:
		data.set(el_index, data[el_index] | (1 << bit_index))
	else:
		data.set(el_index, data[el_index] & ~(1 << bit_index)) 


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


const ONLY_BIT_MORE_BITS_SET = -2
const ONLY_BIT_NO_BITS_SET = -1

func get_only_set_bit() -> int:
	var elem_index: int = -1

	for i in range(data.size()):
		var el: int = data[i]

		if el != 0:
			if elem_index >= 0 or not is_pot(el):
				return ONLY_BIT_MORE_BITS_SET
			elem_index = i

	if elem_index < 0:
		return ONLY_BIT_NO_BITS_SET

	var el: int = data[elem_index]

	return get_first_set_bit_index(el) + elem_index * BITS_PER_INT


class BitSetIterator:
	var arr: PackedInt64Array
	var bit_index: int
	var arr_index: int
	var cur_elem: int

	func _init(bs: BitSet):
		arr = bs.data

	func _iter_init(arg) -> bool:
		if arr.size() == 0:
			return false

		bit_index = -1
		arr_index = 0
		cur_elem = arr[0]
		return _iter_next(arg)

	func _iter_next(_arg) -> bool:
		bit_index += 1

		while true:
			if cur_elem == 0:
				arr_index += 1
				if arr_index >= arr.size():
					return false

				cur_elem = arr[arr_index]
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

func iterator() -> BitSetIterator:
	return BitSetIterator.new(self)

func to_array() -> PackedInt64Array:
	var res: PackedInt64Array = PackedInt64Array()
	
	for b in iterator():
		res.append(b)

	return res



func count_set_bits(pass_if_more_than: int = MAX_INT) -> int:
	var res: int = 0
	
	for i in range(data.size()):
		var el: int = data[i]
		
		while el != 0:
			el ^= (1 << get_first_set_bit_index(el))
			
			res += 1
			
			if res > pass_if_more_than:
				return res
	
	return res



