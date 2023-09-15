extends WFC2DPrecondition2DNullSettings
class_name WFC2DPreconditionDungeonSettings

@export
var class_map: NodePath

func create_precondition(parameters: WFC2DPrecondition2DNullSettings.CreationParameters) -> WFC2DPrecondition:
	assert(not class_map.is_empty())

	var res: WFC2DPreconditionDungeon = WFC2DPreconditionDungeon.new()

	res.rect = parameters.problem_settings.rect

	var class_map_node: Node = parameters.base_node.get_node(class_map)
	assert(class_map_node)
	assert(parameters.problem_settings.rules.mapper.supports_map(class_map_node))
	res.learn_classes(class_map_node, parameters.problem_settings.rules.mapper)

	return res

