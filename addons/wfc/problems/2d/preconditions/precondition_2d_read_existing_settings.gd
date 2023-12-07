extends WFC2DPrecondition2DNullSettings
## Creates a precondition that reads non-empty cells from a target map and requires the WFC
## generation result to contain the same tiles in those cells.
class_name WFC2DPreconditionReadExistingSettings

func create_precondition(parameters: WFC2DPrecondition2DNullSettings.CreationParameters) -> WFC2DPrecondition:
	return WFC2DPreconditionReadExistingMap.new(parameters.target_node, parameters.problem_settings.rules.mapper)
