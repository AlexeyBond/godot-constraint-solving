extends Resource

class_name WFCMapper2D

func learn_from(_map: Node):
	@warning_ignore("assert_always_false")
	assert(false)

func get_used_rect(_map: Node) -> Rect2i:
	@warning_ignore("assert_always_false")
	assert(false)
	return Rect2i()

func read_cell(_map: Node, _coords: Vector2i) -> int:
	"""
	Read cell from map and return a mapped code.
	
	Returns a negative value if cell is empty or mapping for the cell is missing.
	"""
	@warning_ignore("assert_always_false")
	assert(false)
	return -1


func write_cell(_map: Node, _coords: Vector2i, _code: int):
	"""
	Write a cell to map.
	
	code should be inside acceptable range for mapped codes.
	"""
	@warning_ignore("assert_always_false")
	assert(false)

func size() -> int:
	"""
	Returns number of cell types known by the mapper.
	"""
	@warning_ignore("assert_always_false")
	assert(false)
	return 0

func supports_map(_map: Node) -> bool:
	@warning_ignore("assert_always_false")
	assert(false)
	return false

func clear():
	@warning_ignore("assert_always_false")
	assert(false)


func is_ready() -> bool:
	"""
	Return true if this mapper is ready to read/write a map.
	"""
	return size() > 0







