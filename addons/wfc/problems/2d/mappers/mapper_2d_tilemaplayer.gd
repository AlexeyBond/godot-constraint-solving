extends WFCMapper2D
## Mapper for [TileMapLayer] nodes.
class_name WFCTilemapLayerMapper2D

## If enabled, tile probabilities will be read from a built-in [member TileData.probability] tile
## property.
## [br]
## Otherwise a custom data layer with name set in
## [member WFCMapper2D.probability_meta_key] will be used.
@export
var use_builtin_probabilities: bool = true

@export
var tile_set: TileSet = null

@export_storage
var attrs_to_id: Dictionary = {}

var id_to_attrs: Array[Vector4i] = []

func _ensure_tile_map_layer(map: Node) -> TileMapLayer:
	assert(map is TileMapLayer)

	return map as TileMapLayer

func _read_cell_attrs(map: TileMapLayer, coords: Vector2i) -> Vector4i:
	var source := map.get_cell_source_id(coords)
	var atlas_coords := map.get_cell_atlas_coords(coords)
	var alt_tile := map.get_cell_alternative_tile(coords)

	return Vector4i(source, atlas_coords.x, atlas_coords.y, alt_tile)

func learn_from(map_: Node):
	var map := _ensure_tile_map_layer(map_)

	assert(tile_set == null or map.tile_set == tile_set)
	tile_set = map.tile_set

	for cell in map.get_used_cells():
		var cell_attrs := _read_cell_attrs(map, cell)

		if cell_attrs not in attrs_to_id:
			attrs_to_id[cell_attrs] = attrs_to_id.size()

	id_to_attrs.clear()

func _ensure_reverse_mapping():
	if not id_to_attrs.is_empty():
		return

	id_to_attrs.resize(attrs_to_id.size())
	
	for attrs in attrs_to_id.keys():
		id_to_attrs[attrs_to_id[attrs]] = attrs

func get_used_rect(map_: Node) -> Rect2i:
	var map := _ensure_tile_map_layer(map_)
	return map.get_used_rect()

func read_cell(map_: Node, coords: Vector2i) -> int:
	var attrs := _read_cell_attrs(_ensure_tile_map_layer(map_), coords)
	return attrs_to_id.get(attrs, -1)

func write_cell(map_: Node, coords: Vector2i, code: int):
	var map := _ensure_tile_map_layer(map_)
	
	assert(tile_set != null)
	assert(tile_set == map.tile_set)
	_ensure_reverse_mapping()
	assert(code < id_to_attrs.size())
	
	if code < 0:
		map.erase_cell(coords)
	else:
		var attrs := id_to_attrs[code]
		
		map.set_cell(coords, attrs.x, Vector2i(attrs.y, attrs.z), attrs.w)

func clear():
	tile_set = null
	id_to_attrs.clear()
	attrs_to_id.clear()

func size() -> int:
	return attrs_to_id.size()

func supports_map(node: Node) -> bool:
	return node is TileMapLayer

func read_tile_meta(tile: int, meta_name: String) -> Array:
	if tile < 0:
		return []
	_ensure_reverse_mapping()
	assert(tile < id_to_attrs.size())

	var data_layer := tile_set.get_custom_data_layer_by_name(meta_name)

	if data_layer < 0:
		return []
	
	var attrs := id_to_attrs[tile]
	var source := tile_set.get_source(attrs.x)
	
	if source is TileSetAtlasSource:
		var td := (source as TileSetAtlasSource).get_tile_data(Vector2i(attrs.y, attrs.z), attrs.w)
		return [td.get_custom_data_by_layer_id(data_layer)]
	elif source is TileSetScenesCollectionSource:
		pass # TODO
	
	return []

func _read_builtin_probabilities(tile: int) -> float:
	_ensure_reverse_mapping()

	var attrs := id_to_attrs[tile]
	var source := tile_set.get_source(attrs.x)

	if source is TileSetAtlasSource:
		return source.get_tile_data(Vector2i(attrs.y, attrs.z), attrs.w).probability
	elif source is TileSetScenesCollectionSource:
		pass # TODO

	return 1

## See [method WFCMapper2D.read_tile_probability].
## [br]
## May read either from built-in probability property or from a custom data layer.
## See [member use_builtin_probabilities].
func read_tile_probability(tile: int) -> float:
	if tile < 0:
		return 0.0
	assert(tile < size())

	if use_builtin_probabilities:
		return _read_builtin_probabilities(tile)

	return super.read_tile_probability(tile)
