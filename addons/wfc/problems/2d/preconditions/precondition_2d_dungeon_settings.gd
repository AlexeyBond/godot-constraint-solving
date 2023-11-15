extends WFC2DPrecondition2DNullSettings
class_name WFC2DPreconditionDungeonSettings

func create_precondition(parameters: WFC2DPrecondition2DNullSettings.CreationParameters) -> WFC2DPrecondition:
	var res: WFC2DPreconditionDungeon = WFC2DPreconditionDungeon.new()

	res.rect = parameters.problem_settings.rect

	res.learn_classes(parameters.problem_settings.rules.mapper)

	return res

