extends GutTest

func test_set_and_to_array():
	var bs = BitSet.new(129)

	bs.set_bit(0)
	bs.set_bit(0)
	bs.set_bit(63)
	bs.set_bit(128)
	
	assert_eq_deep(
		bs.to_array(),
		PackedInt64Array([0, 63, 128]),
	)

func assert_eq_bits(bs: BitSet, bits: Array):
	assert_eq_deep(bs.to_array(), PackedInt64Array(bits))

func from_bits(size: int, bits: Array) -> BitSet:
	var bs = BitSet.new(size)
	
	for b in bits:
		bs.set_bit(b)

	return bs


func test_init_all_set():
	var bs = BitSet.new(65, true)
	
	assert_eq_bits(
		bs,
		[
			0,1,2,3,4,5,6,7,8,9,
			10,11,12,13,14,15,16,17,18,19,
			20,21,22,23,24,25,26,27,28,29,
			30,31,32,33,34,35,36,37,38,39,
			40,41,42,43,44,45,46,47,48,49,
			50,51,52,53,54,55,56,57,58,59,
			60,61,62,63,64
		]
	)


func test_duplicate():
	var bs = BitSet.new(129)
	
	bs.set_bit(1)
	
	var bs2 = bs.duplicate()
	
	bs2.set_bit(128)
	
	assert_eq_bits(bs, [1])
	assert_eq_bits(bs2, [1, 128])


func test_union():
	assert_eq_bits(
		from_bits(129, [1, 17, 121]).union(from_bits(257, [255, 2])),
		[1, 2, 17, 121, 255]
	)

func test_intersection():
	assert_eq_bits(
		from_bits(129, [1, 42, 54, 95]).intersect(from_bits(100, [42, 95])),
		[42, 95]
	)


func test_get_bit_index():
	var bs = BitSet.new(1)

	for i in range(64):
		assert_eq(
			bs.get_first_set_bit_index(1 << i),
			i,
		)
		assert_eq(
			bs.get_first_set_bit_index((1 << i) | 1),
			i,
		)

func test_get_only_set_bit_one_bit():
	for i in range(129):
		var bs = BitSet.new(129)
		bs.set_bit(i)
		assert_eq(bs.get_only_set_bit(), i)

func test_get_only_set_bit_no_bits():
	var bs = BitSet.new(129)
	
	assert_eq(bs.get_only_set_bit(), BitSet.ONLY_BIT_NO_BITS_SET)

func test_get_only_set_bit_multiple_bits_one_word():
	var bs = BitSet.new(129)
	bs.set_bit(1)
	bs.set_bit(4)
	
	assert_eq(bs.get_only_set_bit(), BitSet.ONLY_BIT_MORE_BITS_SET)

func test_get_only_set_bit_multiple_bits_multiple_words():
	var bs = BitSet.new(129)
	bs.set_bit(1)
	bs.set_bit(120)
	
	assert_eq(bs.get_only_set_bit(), BitSet.ONLY_BIT_MORE_BITS_SET)

func test_count_set_bits():
	assert_eq(
		from_bits(129, []).count_set_bits(),
		0
	)
	assert_eq(
		from_bits(129, [1, 2, 121]).count_set_bits(),
		3
	)

func test_count_set_bits_with_skip():
	assert_eq(
		from_bits(129, [0,1,2,3,4,121,122,128]).count_set_bits(4),
		5
	)











