extends Resource
class_name WFC2DPrecondition2DNullSettings

class CreationParameters:
	var problem_settings: WFC2DProblem.WFC2DProblemSettings
	var target_node: Node
	var base_node: Node

func create_precondition(parameters: CreationParameters) -> WFC2DPrecondition:
	return WFC2DPrecondition.new()
