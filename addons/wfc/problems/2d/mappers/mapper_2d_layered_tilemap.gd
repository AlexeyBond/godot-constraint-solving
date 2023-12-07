extends WFCMapper2D
## A [WFCMapper2D] for [TileMap]s
class_name WFCLayeredTileMapMapper2D

## Dictionary from tile attributes list to numeric tile id.
## [br]
## [color=red]Do not modify manually[/color].
@export
var attrs_to_id: Dictionary = {}

## [TileSet] this mapper uses.
## [br]
## If not set, will be learned from a sample map.
@export
var tile_set: TileSet = null

## Layers this mapper should work with.
## [br]
## If empty, all layers present in sample map will be used.
@export
var layers: Array[int] = []

## If enabled, tile probabilities will be read from a built-in [member TileData.probability] tile
## property.
## [br]
## Otherwise a custom data layer with name set in
## [member WFCMapper2D.probability_meta_key] will be used.
@export
var use_builtin_probabilities: bool = true

## Array of tile attributes where N'th element corresponds to N'th tile type as used by
## [method read_cell], [method write_cell], etc.
## [br]
## It's a reverse of [member attrs_to_id] and is populated lazily based on it's contents.
## [br]
## Nested Arrays types aren't supported but this is an Array[Array[Vector4i]]
var id_to_attrs: Array

func _ensure_tile_map(node: Node) -> TileMap:
	assert(node is TileMap)

	return node as TileMap

func _read_cell_attrs(map: TileMap, coords: Vector2i) -> Array[Vector4i]:
	var cells: Array[Vector4i] = []
	for i in range(len(layers)):
		var layer := layers[i]
		var source: int = map.get_cell_source_id(layer, coords)
		var atlas_coords: Vector2i = map.get_cell_atlas_coords(layer, coords)
		var alt: int = map.get_cell_alternative_tile(layer, coords)
		cells.append(Vector4i(source, atlas_coords.x, atlas_coords.y, alt))
	return cells

## See [method WFCMapper2D.learn_from].
func learn_from(map_: Node):
	var map: TileMap = _ensure_tile_map(map_)
	if len(layers) == 0:
		for i in range(map.get_layers_count()):
			layers.append(i)

	assert(tile_set == null or tile_set == map.tile_set)
	tile_set = map.tile_set
	for i in range(len(layers)):
		var layer := layers[i]
		for cell in map.get_used_cells(layer):
			var cell_attrs: Array[Vector4i] = _read_cell_attrs(map, cell)

			if cell_attrs not in attrs_to_id:
				attrs_to_id[cell_attrs] = attrs_to_id.size()

	id_to_attrs.clear()

func _ensure_reverse_mapping():
	if id_to_attrs.size() > 0:
		return

	id_to_attrs.resize(attrs_to_id.size())

	for attrs in attrs_to_id.keys():
		id_to_attrs[attrs_to_id[attrs]] = attrs

## See [method WFCMapper2D.get_used_rect].
func get_used_rect(map_: Node) -> Rect2i:
	var map: TileMap = _ensure_tile_map(map_)
	return map.get_used_rect()

## See [method WFCMapper2D.read_cell].
func read_cell(map_: Node, coords: Vector2i) -> int:
	var map: TileMap = _ensure_tile_map(map_)
	var attrs: Array[Vector4i] = _read_cell_attrs(map, coords)

	# print('read ', coords, ' -> ', attrs, ' -> ', attrs_to_id.get(attrs, -1))

	return attrs_to_id.get(attrs, -1)

## See [method WFCMapper2D.read_tile_meta].
func read_tile_meta(tile: int, meta_name: String) -> Array:
	if tile < 0:
		return []
	_ensure_reverse_mapping()
	assert(tile < id_to_attrs.size())

	var data_layer := tile_set.get_custom_data_layer_by_name(meta_name)

	if data_layer < 0:
		return []

	var result := []

	for attrs: Vector4i in id_to_attrs[tile]:
		if attrs.x < 0 or attrs.y < 0 or attrs.z < 0 or attrs.w < 0:
			continue

		var source := tile_set.get_source(attrs.x)

		if source is TileSetAtlasSource:
			var td := (source as TileSetAtlasSource).get_tile_data(Vector2i(attrs.y, attrs.z), attrs.w)
			result.append(td.get_custom_data_by_layer_id(data_layer))
		elif source is TileSetScenesCollectionSource:
			pass # TODO

	return result

func _read_builtin_probabilities(tile: int) -> float:
	_ensure_reverse_mapping()
	var probability := 1.0

	for attrs: Vector4i in id_to_attrs[tile]:
		if attrs.x < 0 or attrs.y < 0 or attrs.z < 0 or attrs.w < 0:
			continue

		var source := tile_set.get_source(attrs.x)

		if source is TileSetAtlasSource:
			var td: TileData = source.get_tile_data(Vector2i(attrs.y, attrs.z), attrs.w)
			probability *= td.probability
		elif source is TileSetScenesCollectionSource:
			pass # TODO

	return probability

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

## See [method WFCMapper2D.write_cell].
func write_cell(map_: Node, coords: Vector2i, code: int):
	var map: TileMap = _ensure_tile_map(map_)

	assert(tile_set != null)
	assert(tile_set == map.tile_set)
	_ensure_reverse_mapping()
	assert(code < id_to_attrs.size())
	for i in range(len(layers)):
		var layer := layers[i]
		if code < 0:
			map.erase_cell(layer, coords)
		else:
			var attrs: Vector4i = id_to_attrs[code][i]
			map.set_cell(
				layer,
				coords,
				attrs.x,
				Vector2i(attrs.y, attrs.z),
				attrs.w
			)

## See [method WFCMapper2D.clear].
func clear():
	attrs_to_id.clear()
	id_to_attrs.clear()
	tile_set = null

## See [method WFCMapper2D.size].
func size() -> int:
	return attrs_to_id.size()

## See [method WFCMapper2D.supports_map].
func supports_map(map: Node) -> bool:
	return map is TileMap
