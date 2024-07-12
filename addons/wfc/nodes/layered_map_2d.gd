@tool
extends Node2D

class_name WFC2DLayeredTileMap

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	var layers := 0
	
	for c in get_children():
		if c is TileMapLayer:
			layers += 1
		else:
			warnings.append("Child %s is not a TileMapLayer" % c.name)
	
	if layers == 0:
		warnings.append("No TileMapLayer children")
	elif layers == 1:
		warnings.append("Only one TileMapLayer child found. Add more layers or use TileMapLayer directly instead.")
	
	return warnings

var _layers: Array[Node] = []

func _find_layers() -> Array[Node]:
	var layers: Array[Node] = []
	
	for c in get_children():
		if c is TileMapLayer:
			layers.append(c)
	
	assert(!layers.is_empty())
	
	return layers

func get_layers() -> Array[Node]:
	if _layers.is_empty():
		_layers = _find_layers()
	
	return _layers

func create_layer_mapper(layer: Node) -> WFCMapper2D:
	assert(layer is TileMapLayer)
	return WFCTilemapLayerMapper2D.new()
