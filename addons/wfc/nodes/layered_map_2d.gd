@tool
extends Node
## Multi-layered map for [WFCGenerator2D].
##
## When used with [WFCLayeredMapMapper2D], allows the generator to access multiple map nodes as a
## single map.
##
## The initial intended use-case is a map consisting of multiple [TileMapLayer]s, however, it may be
## used with layers of any supported map type.
class_name WFC2DLayeredMap

## A mapper factory used to create mappers for each layer.
##
## It matters only in case of initial sample map - [WFCLayeredMapMapper2D] will create nested
## mappers using factory provided by the first sample map.
## In other maps it is used to show configuration warnings only.
@export
var mapper_factory: WFC2DMapperFactory = WFC2DMapperFactory.new()

func _get_configuration_warnings() -> PackedStringArray:
	var mf := mapper_factory if mapper_factory != null else WFC2DMapperFactory.new()

	var warnings := PackedStringArray()
	var layers := 0

	for c in get_children():
		if mapper_factory.supports_node(c):
			layers += 1
		else:
			warnings.append("Child %s is not of a supported type" % c.name)

	if layers == 0:
		warnings.append("No children of supported types")
	elif layers == 1:
		warnings.append("Only one child of supported type found. Add more layers or use the child directly instead.")

	return warnings

var _layers: Array[Node] = []

func _find_layers() -> Array[Node]:
	var layers: Array[Node] = []

	for c in get_children():
		if mapper_factory.supports_node(c):
			layers.append(c)

	assert(!layers.is_empty())

	return layers

func get_layers() -> Array[Node]:
	if _layers.is_empty():
		_layers = _find_layers()
	
	return _layers

func create_layer_mapper(layer: Node) -> WFCMapper2D:
	return mapper_factory.create_mapper_for(layer)

# show()/hide() are useful to hide sample maps (at least in demos).
# But they are not available on Node's, only on Node2D and Node3D.
# We don't want WFC2DLayeredMap to be Node2D or Node3D, instead it should work with both,
# so, here are implementations that forward calls to children:

func show():
	for layer in get_layers():
		if layer.has_method('show'):
			layer.show()

func hide():
	for layer in get_layers():
		if layer.has_method('hide'):
			layer.hide()
