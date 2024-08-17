@tool
extends Resource
## A factory that creates mappers for map nodes.
##
## You may want to customize the factory if you're using a custom mapper, e.g. for a custom map node
## type or if you want to customize mapper creation in some other way.
## In such cases, you should create a subclass of this resource, override some methods and use the
## new class in settings of [WFC2DGenerator] node.
##
## The base class creates mappers for all supported node types and will be updated if support for
## new node types is added.
class_name WFC2DMapperFactory

## Create a mapper for given node.
##
## Returns [code]null[/code] if the node is not supported.
func create_mapper_for(node: Node) -> WFCMapper2D:
	match node.get_class():
		"TileMap":
			return WFCLayeredTileMapMapper2D.new()
		"GridMap":
			return WFCGridMapMapper2D.new()
		"TileMapLayer":
			return WFCTilemapLayerMapper2D.new()
		"Node":
			if node is WFC2DLayeredMap:
				return WFCLayeredMapMapper2D.new()
			else:
				return null
		_:
			return null

## Check if given node is supported.
##
## By default it tries to call [method create_mapper_for] and checks if the returned value is
## [code]null[/code].
## If you're overriding [method create_mapper_for] and creation of your mapper type is expensive,
## override this method as well.
func supports_node(node: Node):
	return create_mapper_for(node) != null
