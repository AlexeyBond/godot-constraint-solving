extends WFC2DPrecondition

class_name WFC2DPreconditionRemap

var _node: Node
var _mapper: WFCMapper2D
var _domains_map: Array[WFCBitSet]

func _init(node: Node, mapper: WFCMapper2D, domains_map: Array[WFCBitSet]) -> void:
	assert(mapper.supports_map(node))
	assert(mapper.size() == domains_map.size())

	_node = node
	_mapper = mapper
	_domains_map = domains_map

func read_domain(coords: Vector2i) -> WFCBitSet:
	var read := _mapper.read_cell(_node, coords)
	
	if read < 0:
		return null
	
	return _domains_map[read]
