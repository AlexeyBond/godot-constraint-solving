extends WFC2DPrecondition
class_name WFC2DPreconditionDungeon

var walls_domain: WFCBitSet
var passable_domain: WFCBitSet

var wall_border_size: Vector2i = Vector2i(1, 2)
var free_gap: Vector2i = Vector2i(2, 2)

var room_half_size_base: Vector2i = Vector2i(2, 2)
var room_half_size_variation: Vector2i = Vector2i(2, 2)
var room_probability: float = 0.5

var road_len_base: int = 15
var road_len_variation: int = 5
var fork_probability: float = 0.5
var full_fork_probability: float = 0.5

var passable_area_ratio: float = 0.1

var iterations_limit: int = 1000

var rect: Rect2i
var state: PackedByteArray

const STATE_WALL = 0
const STATE_FREE = 1
const STATE_PASSAGE = 2

func coord_to_id(c: Vector2i) -> int:
	assert(rect.has_point(c))
	
	var rel_c: Vector2i = c - rect.position

	return rel_c.x + rel_c.y * rect.size.x

func id_to_coord(i: int) -> Vector2i:
	var szx: int = rect.size.x
	@warning_ignore("integer_division")
	return Vector2i(i % szx, i / szx)

func read_at(c: Vector2i) -> int:
	return state[coord_to_id(c)]

func learn_classes(node: Node, mapper: WFCMapper2D):
	var used_rect: Rect2i = mapper.get_used_rect(node)

	assert(used_rect.size.y == 1 or used_rect.size.y == 2)

	passable_domain = WFCBitSet.new(mapper.size())

	for i in range(used_rect.size.x):
		var read: int = mapper.read_cell(node, Vector2i(i, 0))
		
		if read >= 0:
			passable_domain.set_bit(read)
	
	walls_domain = WFCBitSet.new(mapper.size())
	
	for i in range(used_rect.size.x):
		var read: int = mapper.read_cell(node, Vector2i(i, 1))
		
		if read >= 0:
			walls_domain.set_bit(read)

	if walls_domain.is_empty():
		walls_domain = passable_domain.invert()

	print_debug("Passage domain: ", passable_domain.format_bits())
	print_debug("Walls domain:   ", walls_domain.format_bits())

func _replace_rect(r: Rect2i, from: int, to: int) -> int:
	var replaced_area: int = 0
	for y in range(r.position.y, r.end.y):
		var offy: int = (y - rect.position.y) * rect.size.x
		for x in range(r.position.x, r.end.x):
			var off: int = offy + x - rect.position.x
			if state[off] == from:
				state[off] = to
				replaced_area += 1

	return replaced_area

func _get_safe_free_rect() -> Rect2i:
	var r: Rect2i = rect.grow_individual(
		-wall_border_size.x, -wall_border_size.y,
		-wall_border_size.x, -wall_border_size.y,
	)

	assert(r.has_area())
	return r

func _get_safe_passable_rect() -> Rect2i:
	var r: Rect2i = _get_safe_free_rect().grow_individual(
		-free_gap.x, -free_gap.y,
		-free_gap.x, -free_gap.y,
	)

	assert(r.has_area())
	return r

func _get_start_point() -> Vector2i:
	var safe_rect: Rect2i = _get_safe_passable_rect()
	# Return a point in the middle of safe rect
	return safe_rect.position + safe_rect.size / 2

class _GrowthPoint:
	var position: Vector2i
	var direction: Vector2i
	
	func _init(p: Vector2i, d: Vector2i):
		self.position = p
		self.direction = d

	func rotate(reverse: bool):
		self.direction = Vector2i(
			self.direction.y,
			-self.direction.x,
		)

		if reverse:
			self.direction *= -1

func _free_space_around(r: Rect2i):
	_replace_rect(
		r.grow_individual(
			free_gap.x, free_gap.y,
			free_gap.x, free_gap.y,
		).intersection(_get_safe_free_rect()),
		STATE_WALL, STATE_FREE,
	)

func _generate_room(center: Vector2i) -> int:
	var mins: Vector2i = center - room_half_size_base - Vector2i(
		randi_range(-room_half_size_variation.x, room_half_size_variation.x),
		randi_range(-room_half_size_variation.y, room_half_size_variation.y),
	)
	var maxs: Vector2i = center + room_half_size_base + Vector2i(
		randi_range(-room_half_size_variation.x, room_half_size_variation.x),
		randi_range(-room_half_size_variation.y, room_half_size_variation.y),
	)
	var r: Rect2i = Rect2i(mins, Vector2i.ZERO).expand(maxs).intersection(_get_safe_passable_rect())

	var area: int = _replace_rect(r, STATE_WALL, STATE_PASSAGE)

	_free_space_around(r)

	return area

func _generate(start_point: Vector2i, start_directions: Array[Vector2i]):
	var growth_points: Array[_GrowthPoint] = []

	assert(not start_directions.is_empty())
	for dir in start_directions:
		assert(dir != Vector2i.ZERO)
		growth_points.append(_GrowthPoint.new(start_point, dir))

	var passable_rect: Rect2i = _get_safe_passable_rect()

	print('Total rect: ', rect, ' passable rect: ', passable_rect)

	assert(passable_area_ratio > 0.0 and passable_area_ratio < 1.0)
	var remaining_area: int = passable_area_ratio * passable_rect.get_area()
	assert(remaining_area > 0)
	var remaining_iterations: int = iterations_limit

	remaining_area -= _generate_room(start_point)

	while remaining_area > 0 and remaining_iterations > 0:
		remaining_iterations -= 1

		assert(not growth_points.is_empty())
		var gp: _GrowthPoint = growth_points.pop_front()
		var initial_position: Vector2i = gp.position

		var road_length: int = road_len_base + randi_range(-road_len_variation, road_len_variation)

		for i in range(road_length):
			var next_pos: Vector2i = gp.position + gp.direction

			if not passable_rect.has_point(next_pos):
				break

			gp.position = next_pos

		var road_rect: Rect2i = Rect2i(initial_position, Vector2i.ONE).expand(gp.position)

		remaining_area -= _replace_rect(road_rect, STATE_WALL, STATE_PASSAGE)
		remaining_area -= _replace_rect(road_rect, STATE_FREE, STATE_PASSAGE)

		if room_probability > randf():
			remaining_area -= _generate_room(gp.position)

		_free_space_around(road_rect)

		gp.rotate(randf() > 0.5)

		growth_points.push_back(gp)

func prepare():
	assert(rect.has_area())

	state.resize(rect.get_area())

	_generate(_get_start_point(), [Vector2i.DOWN, Vector2i.UP])
	#var test_road_rect: Rect2i = Rect2i(10, 10, 100, 1)
	#_replace_rect(test_road_rect, STATE_WALL, STATE_PASSAGE)
	#_replace_rect(test_road_rect.grow(2), STATE_WALL, STATE_FREE)


func read_domain(coords: Vector2i) -> WFCBitSet:
	assert(state.size() == rect.get_area())

	if not rect.has_point(coords):
		@warning_ignore("assert_always_false")
		assert(false)
		return null

	match state[coord_to_id(coords)]:
		STATE_WALL:
			return walls_domain
		STATE_PASSAGE:
			return passable_domain
		_:
			return null



