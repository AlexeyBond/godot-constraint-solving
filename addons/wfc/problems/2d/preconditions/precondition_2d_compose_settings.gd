extends WFC2DPrecondition2DNullSettings
## Creates a preconditions composed of multiple preconditions.
##
## A tile will be allowed in a cell only if all sub-preconditions allow it.
class_name WFC2DPreconditionComposeSettings

## The preconditions to compose.
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
