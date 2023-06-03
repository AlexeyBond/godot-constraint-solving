extends Resource

class_name BitMatrix

@export
var rows: Array[BitSet]

var width: int
var height: int

func _init(w: int, h: int):
	width = w
	height = h

	for i in range(height):
		rows.append(BitSet.new(width))

func copy() -> BitMatrix:
	var res: BitMatrix = BitMatrix.new(0, 0)

	res.width = width
	res.height = height

	for i in range(height):
		res.rows.append(rows[i].copy())

	return res

func set_bit(x: int, y: int, value: bool = true):
	assert(y >= 0 and y < height)
	
	rows[y].set_bit(x, value)

func transpose() -> BitMatrix:
	var res: BitMatrix = BitMatrix.new(height, width)
	
	for y in range(height):
		for x in rows[y].iterator():
			res.set_bit(y, x)
	
	return res

func transform(input: BitSet) -> BitSet:
	assert(input.size == height)
	
	var res: BitSet = BitSet.new(width)
	
	for y in input.iterator():
		res.union_in_place(rows[y])
	
	return res

func complete():
	"""
	Find all structures like (including rotated)
	
	1 * 1
	* * *
	1 * 0
	
	and complete them to
	
	1 * 1
	* * *
	1 * 1
	"""
	# TODO: Find the right name for this operation
	for i in range(height):
		var ri: BitSet = rows[i]
		for j in range(height):
			if i != j:
				var rj: BitSet = rows[j]
				
				if ri.intersects_with(rj):
					rj.union_in_place(ri)


func format_bits() -> String:
	var res: String = '('

	for i in range(height):
		res += '\n\t'
		res += rows[i].format_bits()
		res += ','
	
	res += '\n)'
	
	return res




