extends WFC2DPrecondition
class_name WFC2DPreconditionCompose

var _preconditions: Array[WFC2DPrecondition] = []

func _init(preconditions: Array[WFC2DPrecondition]):
	_preconditions = preconditions

func prepare():
	for pc in _preconditions:
		pc.prepare()

func read_domain(coords: Vector2i) -> WFCBitSet:
	var result: WFCBitSet = null
	
	for pc in _preconditions:
		var partial_result: WFCBitSet = pc.read_domain(coords)

		if partial_result != null:
			if result != null:
				result = partial_result.intersect(result)
			else:
				result = partial_result

	return result
