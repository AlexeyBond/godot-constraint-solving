extends WFC2DPrecondition

class_name WFC2DPreconditionRemap

var _node: Node
var _mapper: WFCMapper2D
var _domains_map: Array[WFCBitSet]
var _default_domain: WFCBitSet

func _init(node: Node, mapper: WFCMapper2D, domains_map: Array[WFCBitSet], default_domain: WFCBitSet = null) -> void:
	assert(mapper.supports_map(node))
	assert(mapper.size() == domains_map.size())

	_node = node
	_mapper = mapper
	_domains_map = domains_map
	_default_domain = default_domain

func read_domain(coords: Vector2i) -> WFCBitSet:
	var read := _mapper.read_cell(_node, coords)

	if read < 0:
		return _default_domain

	return _domains_map[read]
