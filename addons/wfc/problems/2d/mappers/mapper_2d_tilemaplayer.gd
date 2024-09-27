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

func _check_terrain_adjacency_to_empty(
	td: TileData,
	edge: TileSet.CellNeighbor,
	corner1: TileSet.CellNeighbor,
	corner2: TileSet.CellNeighbor,
) -> InitialRule:
	if td == null:
		return InitialRule.UNKNOWN

	if td.is_valid_terrain_peering_bit(edge) and td.get_terrain_peering_bit(edge) >= 0:
		return InitialRule.FORBIDDEN

	if td.is_valid_terrain_peering_bit(corner1) and td.get_terrain_peering_bit(corner1) >= 0:
		return InitialRule.FORBIDDEN

	if td.is_valid_terrain_peering_bit(corner2) and td.get_terrain_peering_bit(corner2) >= 0:
		return InitialRule.FORBIDDEN

	return InitialRule.UNKNOWN

## Get a [TileData] for given tile id.
##
## Returns [code]null[/code] if tile is an empty tile ([code]-1[/code]) or the corresponding source
## is not an atlas source.
func _get_tile_data_for(tile: int) -> TileData:
	_ensure_reverse_mapping()

	if tile < 0:
		return null

	var attrs := id_to_attrs[tile]
	var source := tile_set.get_source(attrs.x) as TileSetAtlasSource

	if source == null:
		return null

	return source.get_tile_data(Vector2i(attrs.y, attrs.z), attrs.w)

func _check_terrain_adjacency(
	tile1: int,
	edge1: TileSet.CellNeighbor,
	corner11: TileSet.CellNeighbor,
	corner12: TileSet.CellNeighbor,
	tile2: int,
	edge2: TileSet.CellNeighbor,
	corner21: TileSet.CellNeighbor,
	corner22: TileSet.CellNeighbor,
) -> InitialRule:
	var td1 := _get_tile_data_for(tile1)
	var td2 := _get_tile_data_for(tile2)

	if td1 == null:
		return _check_terrain_adjacency_to_empty(td2, edge2, corner21, corner22)

	if td2 == null:
		return _check_terrain_adjacency_to_empty(td1, edge1, corner11, corner12)

	var ts1 := td1.terrain_set
	var ts2 := td2.terrain_set

	if ts1 < 0:
		if ts2 < 0:
			return InitialRule.UNKNOWN
		return _check_terrain_adjacency_to_empty(td2, edge2, corner21, corner22)

	if ts2 < 0:
		return _check_terrain_adjacency_to_empty(td1, edge1, corner11, corner12)

	if ts1 != ts2:
		# Tiles with different terrain sets can be neighbours if the corresponding edges/corners do
		# not have terrain set.
		return max(
			_check_terrain_adjacency_to_empty(td2, edge2, corner21, corner22),
			_check_terrain_adjacency_to_empty(td1, edge1, corner11, corner12)
		)

	var result := InitialRule.UNKNOWN

	if td1.is_valid_terrain_peering_bit(edge1):
		var bit := td1.get_terrain_peering_bit(edge1)
		if bit != td2.get_terrain_peering_bit(edge2):
			return InitialRule.FORBIDDEN
		if bit >= 0:
			# Allow tile combination if there is at least one matching terrain bit
			result = InitialRule.ALLOWWED

	if td1.is_valid_terrain_peering_bit(corner11):
		var bit := td1.get_terrain_peering_bit(corner11)
		if bit != td2.get_terrain_peering_bit(corner21):
			return InitialRule.FORBIDDEN
		if bit >= 0:
			result = InitialRule.ALLOWWED

	if td1.is_valid_terrain_peering_bit(corner12):
		var bit := td1.get_terrain_peering_bit(corner12)
		if bit != td2.get_terrain_peering_bit(corner22):
			return InitialRule.FORBIDDEN
		if bit >= 0:
			result = InitialRule.ALLOWWED

	return result

## @inheritdoc
func get_initial_rule(tile1: int, tile2: int, direction: Vector2i) -> InitialRule:
	assert(is_ready())

	if tile_set.tile_shape == TileSet.TileShape.TILE_SHAPE_SQUARE:
		if direction.length_squared() != 1:
			return InitialRule.UNKNOWN
		if direction.x + direction.y < 0:
			return get_initial_rule(tile2, tile1, -direction)
		if direction == Vector2i(1, 0):
			return _check_terrain_adjacency(
				tile1,
				TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
				TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
				TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
				tile2,
				TileSet.CELL_NEIGHBOR_LEFT_SIDE,
				TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
				TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
			)
		if direction == Vector2i(0, 1):
			return _check_terrain_adjacency(
				tile1,
				TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
				TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
				TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
				tile2,
				TileSet.CELL_NEIGHBOR_TOP_SIDE,
				TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
				TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
			)
	else:
		pass # Unsupported tile shape/layout. TODO: Print a warning (but only once)?

	return InitialRule.UNKNOWN

func has_initial_rules() -> bool:
	assert(is_ready())

	return tile_set.get_terrain_sets_count() > 0
