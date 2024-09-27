extends WFCMapper2D
## A mapper for [WFC2DLayeredMap]
class_name WFCLayeredMapMapper2D

## Expected names of layer nodes.
##
## Leave blank if you want the mapper to learn them from sample.
@export
var layer_names: Array[String]

## Mappers for each layer.
##
## Leave blank if you want the mapper to learn layers from sample.
@export
var layer_mappers: Array[WFCMapper2D]

## Use metadata instead of [method WFCMapper2D.read_tile_probability] calls to get tile
## probabilities from layers.
@export
var use_probability_meta: bool = false

@export_storage
var attrs_to_id: Dictionary #[PackedInt32Array, int]

var id_to_attrs: Array[PackedInt32Array] = []

func _ensure_layered_map(map: Node) -> WFC2DLayeredMap:
	assert(map is WFC2DLayeredMap)
	return map as WFC2DLayeredMap

func _get_layer_name(layer_node: Node) -> String:
	return layer_node.name

func _learn_layers_from(layer_nodes: Array[Node]):
	for layer_node in layer_nodes:
		layer_names.append(_get_layer_name(layer_node))
		layer_mappers.append(WFCTilemapLayerMapper2D.new())

func _read_attrs(layer_nodes: Array[Node], coords: Vector2i) -> PackedInt32Array:
	var attrs := PackedInt32Array()
	var empty := true
	attrs.resize(layer_mappers.size())

	for i in layer_mappers.size():
		var cell := layer_mappers[i].read_cell(layer_nodes[i], coords)
		attrs[i] = cell
		if cell >= 0:
			empty = false

	if empty:
		return []

	return attrs

func _ensure_reverse_mapping():
	if id_to_attrs.size() == attrs_to_id.size():
		return

	id_to_attrs.resize(attrs_to_id.size())

	for attrs in attrs_to_id:
		id_to_attrs[attrs_to_id[attrs]] = attrs

func learn_from(map_: Node):
	assert(layer_mappers.size() == layer_names.size())

	var map := _ensure_layered_map(map_)
	var layer_nodes := map.get_layers()

	if layer_names.is_empty() and layer_mappers.is_empty():
		_learn_layers_from(layer_nodes)
	else:
		assert(layer_mappers.size() == layer_nodes.size())

	for i in layer_nodes.size():
		var layer_node := layer_nodes[i]
		assert(layer_names[i] == _get_layer_name(layer_node))
		layer_mappers[i].learn_from(layer_node)

	var rect := get_used_rect(map)
	
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var attrs := _read_attrs(layer_nodes, Vector2i(x, y))
			
			if attrs.is_empty():
				continue
			
			if attrs in attrs_to_id:
				continue
			
			attrs_to_id[attrs] = attrs_to_id.size()
			id_to_attrs.clear()

func get_used_rect(map: Node) -> Rect2i:
	assert(layer_names.size() == layer_mappers.size())
	assert(layer_names.size() > 0)

	var layer_nodes := _ensure_layered_map(map).get_layers()
	assert(layer_nodes.size() == layer_mappers.size())

	var rect: Rect2i

	for i in layer_nodes.size():
		if !rect.has_area():
			rect = layer_mappers[i].get_used_rect(layer_nodes[i])
		else:
			var r := layer_mappers[i].get_used_rect(layer_nodes[i])
			if r.has_area():
				rect.expand(r.position)
				rect.expand(r.end - Vector2i.ONE)

	return rect

func read_cell(map: Node, coords: Vector2i) -> int:
	assert(layer_mappers.size() == layer_names.size())
	assert(layer_mappers.size() > 0)
	assert(is_ready())

	var layer_nodes := _ensure_layered_map(map).get_layers()
	var attrs := _read_attrs(layer_nodes, coords)
	return attrs_to_id.get(attrs, -1)

func read_tile_meta(tile: int, meta_name: String) -> Array:
	if tile < 0:
		return []

	assert(layer_mappers.size() == layer_names.size())
	assert(tile < size())

	var res = []

	_ensure_reverse_mapping()
	var attrs := id_to_attrs[tile]
	assert(attrs.size() == layer_mappers.size())

	for i in attrs.size():
		res.append_array(layer_mappers[i].read_tile_meta(attrs[i], meta_name))

	return res

func read_tile_probability(tile: int) -> float:
	if use_probability_meta:
		return super.read_tile_probability(tile)

	assert(layer_mappers.size() > 0)
	assert(tile < size())

	if tile < 0:
		return 0.0

	var probability := 1.0

	_ensure_reverse_mapping()
	var attrs := id_to_attrs[tile]
	assert(attrs.size() == layer_mappers.size())

	for i in attrs.size():
		if attrs[i] >= 0:
			probability *= layer_mappers[i].read_tile_probability(attrs[i])

	return probability

func write_cell(map: Node, coords: Vector2i, code: int):
	assert(layer_mappers.size() == layer_names.size())
	assert(code < size())

	var layer_nodes := _ensure_layered_map(map).get_layers()
	assert(layer_nodes.size() == layer_mappers.size())

	if code < 0:
		for i in layer_nodes.size():
			assert(layer_nodes[i].name == layer_names[i])
			layer_mappers[i].write_cell(layer_nodes[i], coords, -1)
		return

	_ensure_reverse_mapping()
	var attrs := id_to_attrs[code]

	assert(attrs.size() == layer_nodes.size())

	for i in layer_nodes.size():
		assert(layer_nodes[i].name == layer_names[i])
		layer_mappers[i].write_cell(layer_nodes[i], coords, attrs[i])

func size() -> int:
	return attrs_to_id.size()

func supports_map(map: Node) -> bool:
	return map is WFC2DLayeredMap

## @inheritdoc
func get_initial_rule(tile1: int, tile2: int, direction: Vector2i) -> InitialRule:
	_ensure_reverse_mapping()

	var result := InitialRule.UNKNOWN

	for layer in range(layer_mappers.size()):
		var tile1_layer: int = -1
		var tile2_layer: int = -1

		if tile1 >= 0:
			tile1_layer = id_to_attrs[tile1][layer]

		if tile2 >= 0:
			tile2_layer = id_to_attrs[tile2][layer]

		result = max(result, layer_mappers[layer].get_initial_rule(tile1_layer, tile2_layer, direction))

		if result == InitialRule.FORBIDDEN:
			break

	return result

## @inheritdoc
func has_initial_rules() -> bool:
	assert(is_ready())

	for mapper in layer_mappers:
		if not mapper.has_initial_rules():
			return false

	return true


func clear():
	layer_names.clear()
	layer_mappers.clear()
	attrs_to_id.clear()
	id_to_attrs.clear()
