extends WFC2DPrecondition2DNullSettings

class_name WFC2DPrecondition2DRemapByMapSettings

## A map that defines possible tile replacements.
##
## The tiles placed in the target map may be replaced by any tiles that are present in same rows of
## this class map.
##
## E.g. if there are tiles A B C D in the tileset, and the class map contains a row of A B and A C,
## then A tile may be replaced by either A, B or C; B - by A or B; C - by A or C; and the tile D
## will always remain as is.
@export_node_path
var class_map: NodePath

## Remap empty cells of target map to tiles from first row of class map.
##
## If not set, empty cells may be filled with any tile.
@export
var remap_empty: bool = false

func _learn_classes(mapper: WFCMapper2D, map: Node) -> Array[WFCBitSet]:
	var res: Array[WFCBitSet] = []
	
	for i in range(mapper.size()):
		var set := WFCBitSet.new(mapper.size())
		set.set_bit(i, true)
		res.push_back(set)

	var used_rect := mapper.get_used_rect(map)

	for row in range(used_rect.position.y, used_rect.end.y):
		var row_set := WFCBitSet.new(mapper.size())
		for col in range(used_rect.position.x, used_rect.end.x):
			var tile := mapper.read_cell(map, Vector2i(col, row))
			if tile >= 0:
				row_set.set_bit(tile, true)

		for tile in row_set.iterator():
			res[tile].union_in_place(row_set)

	return res

func create_precondition(parameters: CreationParameters) -> WFC2DPrecondition:
	assert(class_map != null)
	var class_map_node := parameters.generator_node.get_node(class_map)
	assert(parameters.problem_settings.rules.mapper.supports_map(class_map_node))
	
	var classes := _learn_classes(parameters.problem_settings.rules.mapper, class_map_node)
	var empty_domain: WFCBitSet = null
	
	if remap_empty:
		empty_domain = classes[0]

	return WFC2DPreconditionRemap.new(
		parameters.target_node,
		parameters.problem_settings.rules.mapper,
		classes,
		empty_domain,
	)
