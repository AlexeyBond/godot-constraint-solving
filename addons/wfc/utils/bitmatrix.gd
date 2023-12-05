extends Resource
## A matrix of [member width]x[member height] bits.
class_name WFCBitMatrix

## Rows of the matrix.
## Each row is stored as a [WFCBitSet].
@export
var rows: Array[WFCBitSet]

## Width of the matrix
@export
var width: int

## Height of the matrix
@export
var height: int

func _init(w: int, h: int):
	width = w
	height = h

	for i in range(height):
		rows.append(WFCBitSet.new(width))

## Creates a copy of this matrix.
func copy() -> WFCBitMatrix:
	var res: WFCBitMatrix = WFCBitMatrix.new(0, 0)

	res.width = width
	res.height = height

	for i in range(height):
		res.rows.append(rows[i].copy())

	return res

## Set [param x]th bit in [param y]th row.
func set_bit(x: int, y: int, value: bool = true):
	assert(y >= 0 and y < height)

	rows[y].set_bit(x, value)

## Create a new matrix that is a [url=https://en.wikipedia.org/wiki/Transpose]transposition[/url] of
## this matrix.
func transpose() -> WFCBitMatrix:
	var res: WFCBitMatrix = WFCBitMatrix.new(height, width)

	for y in range(height):
		for x in rows[y].iterator():
			res.set_bit(y, x)

	return res

## Multiply given [WFCBitSet] (considered as a bit-vector) by this matrix.
## [br]
## [i](OR multiply this matrix by the vector; operation order with matrices is hard).[/i]
## [br]
## [WFCBitSet.size] of input vector must match [member width] of this matrix.
func transform(input: WFCBitSet) -> WFCBitSet:
	assert(input.size == height)

	var res: WFCBitSet = WFCBitSet.new(width)

	for y in input.iterator():
		res.union_in_place(rows[y])

	return res

## Find all structures like (including rotated)
## [codeblock]
## 1 * 1
## * * *
## 1 * 0
## [/codeblock]
## and complete them to
## [codeblock]
## 1 * 1
## * * *
## 1 * 1
## [/codeblock]
## Despite how useful it is, I have no idea what is a correct name for this operation.
## If you know the name - plase submit a PR/issue.
## But for now let's call it [i]The Bondarenko Operator[/i].
func complete():
	for i in range(height):
		var ri: WFCBitSet = rows[i]
		for j in range(height):
			if i != j:
				var rj: WFCBitSet = rows[j]

				if ri.intersects_with(rj):
					rj.union_in_place(ri)

## Prints this matrix to string.
## [br]
## The output will look like
## [codeblock]
## "(
##     (1, 0),
##     (0, 1),
## )"
## [/codeblock]
func format_bits() -> String:
	var res: String = '('

	for i in range(height):
		res += '\n\t'
		res += rows[i].format_bits()
		res += ','

	res += '\n)'

	return res

## For an NxN bit-matrix, representing links in a direct graph of N nodes, returns the length of the
## longest path that is a shortest path between certain two nodes.
## [br]
## Returns -1 if graph consists of few unconnected sub-graphs (and thus paths between some pairs of
## nodes do not exist).
func get_longest_path() -> int:
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
