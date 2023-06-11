extends Resource

class_name WFCBitMatrix

@export
var rows: Array[WFCBitSet]

var width: int
var height: int

func _init(w: int, h: int):
	width = w
	height = h

	for i in range(height):
		rows.append(WFCBitSet.new(width))

func copy() -> WFCBitMatrix:
	var res: WFCBitMatrix = WFCBitMatrix.new(0, 0)

	res.width = width
	res.height = height

	for i in range(height):
		res.rows.append(rows[i].copy())

	return res

func set_bit(x: int, y: int, value: bool = true):
	assert(y >= 0 and y < height)
	
	rows[y].set_bit(x, value)

func transpose() -> WFCBitMatrix:
	var res: WFCBitMatrix = WFCBitMatrix.new(height, width)
	
	for y in range(height):
		for x in rows[y].iterator():
			res.set_bit(y, x)
	
	return res

func transform(input: WFCBitSet) -> WFCBitSet:
	assert(input.size == height)
	
	var res: WFCBitSet = WFCBitSet.new(width)
	
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
		var ri: WFCBitSet = rows[i]
		for j in range(height):
			if i != j:
				var rj: WFCBitSet = rows[j]
				
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

func get_longest_path() -> int:
	"""
	For an NxN bit-matrix, replresenting links in a direct graph of N nodes,
	returns the length of the longest path that is a shortest path between
	certain two nodes.
	
	Returns -1 if graph consists of few unconnected sub-graphs (and thus paths
	between some pairs of nodes do not exist).
	"""
	assert(width == height)

	var all_set: WFCBitSet = WFCBitSet.new(width, true)
	var longest_known_path: int = -1

	for start in range(width):
		var cur: WFCBitSet = WFCBitSet.new(width)
		cur.set_bit(start, true)
		
		for path_len in range(1, width):
			cur = transform(cur)
			if cur.equals(all_set):
				if path_len > longest_known_path:
					longest_known_path = path_len

				break

	return longest_known_path




