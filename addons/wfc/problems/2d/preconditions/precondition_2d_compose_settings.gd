extends WFC2DPrecondition2DNullSettings
class_name WFC2DPreconditionComposeSettings

@export
var preconditions: Array[WFC2DPrecondition2DNullSettings] = []

func create_precondition(parameters: WFC2DPrecondition2DNullSettings.CreationParameters) -> WFC2DPrecondition:
	var created: Array[WFC2DPrecondition] = []
	
	for pcs in preconditions:
		created.append(pcs.create_precondition(parameters))

	match created.size():
		0:
			return WFC2DPrecondition.new()
		1:
			return created[0]
		_:
			return WFC2DPreconditionCompose.new(created)
