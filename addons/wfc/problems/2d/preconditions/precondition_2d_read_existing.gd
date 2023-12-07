extends WFC2DPrecondition
class_name WFC2DPreconditionReadExistingMap

var _node: Node
var _mapper: WFCMapper2D
var _domain_cache: Dictionary = {}

func _init(node: Node, mapper: WFCMapper2D):
	_node = node
	_mapper = mapper

func read_domain(coords: Vector2i) -> WFCBitSet:
	var read: int = _mapper.read_cell(_node, coords)

	if read < 0:
		return null

	if read in _domain_cache:
		return _domain_cache[read]

	var domain: WFCBitSet = WFCBitSet.new(_mapper.size())
	domain.set_bit(read, true)

	_domain_cache[read] = domain

	return domain
