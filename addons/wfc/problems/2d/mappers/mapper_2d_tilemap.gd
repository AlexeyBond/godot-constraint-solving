extends WFCMapper2D

class_name WFCTileMapMapper2D

@export
var attrs_to_id: Dictionary = {}

@export
var tile_set: TileSet = null

@export
var layer: int = 0

var id_to_attrs: Array[Vector4i]

func _ensure_tile_map(node: Node) -> TileMap:
	assert(node is TileMap)
	
	return node as TileMap

func _read_cell_attrs(map: TileMap, coords: Vector2i) -> Vector4i:
	var source: int = map.get_cell_source_id(layer, coords)
	var atlas_coords: Vector2i = map.get_cell_atlas_coords(layer, coords)
	var alt: int = map.get_cell_alternative_tile(layer, coords)

	return Vector4i(source, atlas_coords.x, atlas_coords.y, alt)

func learn_from(map_: Node):
	var map: TileMap = _ensure_tile_map(map_)

	assert(tile_set == null or tile_set == map.tile_set)
	tile_set = map.tile_set

	for cell in map.get_used_cells(layer):
		var cell_attrs: Vector4i = _read_cell_attrs(map, cell)

		if cell_attrs not in attrs_to_id:
			attrs_to_id[cell_attrs] = attrs_to_id.size()

	id_to_attrs.clear()


func _ensure_reverse_mapping():
	if id_to_attrs.size() > 0:
		return

	id_to_attrs.resize(attrs_to_id.size())

	for attrs in attrs_to_id.keys():
		id_to_attrs[attrs_to_id[attrs]] = attrs

func get_used_rect(map_: Node) -> Rect2i:
	var map: TileMap = _ensure_tile_map(map_)
	return map.get_used_rect()

func read_cell(map_: Node, coords: Vector2i) -> int:
	var map: TileMap = _ensure_tile_map(map_)

	var attrs: Vector4i = _read_cell_attrs(map, coords)
	
	#print('read ', coords, ' -> ', attrs, ' -> ', attrs_to_id.get(attrs, -1))

	return attrs_to_id.get(attrs, -1)


func write_cell(map_: Node, coords: Vector2i, code: int):
	var map: TileMap = _ensure_tile_map(map_)

	assert(tile_set != null)
	assert(tile_set == map.tile_set)
	_ensure_reverse_mapping()
	assert(code < id_to_attrs.size())

	if code < 0:
		map.erase_cell(layer, coords)
	else:
		var attrs: Vector4i = id_to_attrs[code]

		map.set_cell(
			layer, coords,
			attrs.x,
			Vector2i(attrs.y, attrs.z),
			attrs.w
		)

func clear():
	attrs_to_id.clear()
	id_to_attrs.clear()
	tile_set = null

func size() -> int:
	return attrs_to_id.size()

func supports_map(map: Node) -> bool:
	return map is TileMap



