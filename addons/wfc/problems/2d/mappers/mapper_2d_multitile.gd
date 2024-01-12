extends WFCMapper2D
## A [WFCMapper2D] that works with rects of underlying map as with single tiles.
## [br]
## It uses another [WFCMapper2D] (specified by [member mapper]) to interact with the map itself.
## So, it may work with any map type a [WFCMapper2D] implementation exists for.
class_name WFC2DMultitileMapper

## Mapper used to access the underlying map.
## [br]
## Must be set manually to a non-[code]null[/code] value.
@export
var mapper: WFCMapper2D

## Size of tile in tiles of underlying map.
## [br]
## Both [code]x[/code] and [code]y[/code] components must be positive.
@export
var tile_size: Vector2i = Vector2i(2, 2)

## Offset of top left corner of tile at [code](0, 0)[/code] from [code](0, 0)[/code] of underlying
## map.
@export
var offset: Vector2i = Vector2i.ZERO

## Allow tiles that contain some empty sub-tiles.
##
## @experimental
@export
var allow_partial: bool = false

## Mapping from tile content (represented as [PackedInt32Array]) to tile id.
## [br]
## Actual type is [code]Dictionary[PackedInt32Array, int][/code].
## [br]
## [color=red]Do not modify manually[/color].
@export
var tiles_to_id: Dictionary = {}

## Array of sub-tile arrays for each tile type.
## [br]
## [color=red]Do not modify manually[/color].
var id_to_tiles: Array[PackedInt32Array] = []

func _read_array_at(map: Node, pos: Vector2i) -> PackedInt32Array:
	var origin := pos * tile_size + offset
	var result: PackedInt32Array = []

	for x in range(origin.x, origin.x + tile_size.x):
		for y in range(origin.y, origin.y + tile_size.y):
			result.append(mapper.read_cell(map, Vector2i(x, y)))

	return result

func _ensure_reverse_mapping():
	assert(tiles_to_id.size() > 0)

	if tiles_to_id.size() == id_to_tiles.size():
		return

	id_to_tiles = []
	id_to_tiles.resize(tiles_to_id.size())

	for tiles in tiles_to_id.keys():
		id_to_tiles[tiles_to_id[tiles]] = tiles

func _is_readable_tile(arr: PackedInt32Array) -> int:
	if allow_partial:
		for st in arr:
			if st >= 0:
				return true
		return false
	else:
		for st in arr:
			if st < 0:
				return false
		return true

## See [method WFCMapper2D.learn_from].
func learn_from(map: Node):
	assert(mapper != null)
	assert(tile_size.x > 0)
	assert(tile_size.y > 0)
	assert(tile_size.x > 1 or tile_size.y > 1)

	mapper.learn_from(map)

	var used_rect := get_used_rect(map)
	var sub_tiles_per_tile: int = tile_size.x * tile_size.y

	for x in range(used_rect.position.x, used_rect.end.x):
		for y in range(used_rect.position.y, used_rect.end.y):
			var arr := _read_array_at(map, Vector2i(x, y))
			if _is_readable_tile(arr) and (arr not in tiles_to_id):
				tiles_to_id[arr] = tiles_to_id.size()

func _div_round_up(a: int, b: int):
	var res: int = a / b

	if res * b < a:
		res += 1

	return res

func _div_round_down(a: int, b: int):
	var res: int = a / b

	if res * b > a:
		res -= 1

	return res

## See [method WFCMapper2D.get_used_rect].
func get_used_rect(map: Node) -> Rect2i:
	var inner_rect := mapper.get_used_rect(map)
	inner_rect.position -= offset
	var result: Rect2i = Rect2i()

	if allow_partial:
		result.position = Vector2i(
			_div_round_down(inner_rect.position.x, tile_size.x),
			_div_round_down(inner_rect.position.y, tile_size.y),
		)
		result.end = Vector2i(
			_div_round_up(inner_rect.end.x, tile_size.x),
			_div_round_up(inner_rect.end.y, tile_size.y),
		)
	else:
		result.position = Vector2i(
			_div_round_up(inner_rect.position.x, tile_size.x),
			_div_round_up(inner_rect.position.y, tile_size.y),
		)
		result.end = Vector2i(
			_div_round_down(inner_rect.end.x, tile_size.x),
			_div_round_down(inner_rect.end.y, tile_size.y),
		)

	return result

## See [method WFCMapper2D.read_cell].
func read_cell(map: Node, coords: Vector2i) -> int:
	var a := _read_array_at(map, coords)

	if a in tiles_to_id:
		return tiles_to_id[a]

	return -1

## See [method WFCMapper2D.read_tile_meta].
func read_tile_meta(tile: int, meta_name: String) -> Array:
	_ensure_reverse_mapping()
	var result: Array = []

	for sub_tile in id_to_tiles[tile]:
		if sub_tile >= 0:
			result.append_array(mapper.read_tile_meta(sub_tile, meta_name))

	return result

## See [method WFCMapper2D.read_tile_probability].
func read_tile_probability(tile: int) -> float:
	if tile < 0:
		return 0.0
	assert(tile < size())

	_ensure_reverse_mapping()

	var probability := 1.0

	for sub_tile in id_to_tiles[tile]:
		if sub_tile >= 0:
			probability *= mapper.read_tile_probability(sub_tile)

	return probability

## See [method WFCMapper2D.write_cell].
func write_cell(map: Node, coords: Vector2i, code: int):
	assert(code < size())

	_ensure_reverse_mapping()

	var sub_tiles: PackedInt32Array

	if code >= 0:
		sub_tiles = id_to_tiles[code]

	var origin := coords * tile_size + offset
	var i: int = 0
	for x in range(origin.x, origin.x + tile_size.x):
		for y in range(origin.y, origin.y + tile_size.y):
			var sub_code: int = -1
			if not sub_tiles.is_empty():
				sub_code = sub_tiles[i]
				i += 1

			mapper.write_cell(map, Vector2i(x, y), sub_code)

## See [method WFCMapper2D.size].
func size() -> int:
	return tiles_to_id.size()

## See [method WFCMapper2D.supports_map].
func supports_map(map: Node) -> bool:
	return mapper.supports_map(map)

## See [method WFCMapper2D.clear].
func clear():
	mapper.clear()
	tiles_to_id.clear()
	id_to_tiles.clear()

## See [method WFCMapper2D.is_ready].
func is_ready() -> bool:
	return mapper.is_ready() and size() > 0
