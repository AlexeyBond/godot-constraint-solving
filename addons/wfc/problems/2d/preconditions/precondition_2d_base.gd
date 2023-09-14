class_name WFC2DPrecondition
extends RefCounted

func prepare():
	"""
	May calculate data necessary for this precondition.
	
	Must be called exactly once on one object.
	"""
	pass

func read_domain(coords: Vector2i) -> WFCBitSet:
	"""
	Returns initial domain of a cell at given coordinates.
	
	Returns null if this precondition doesn't limit domain of cell at given coordinates.
	
	Must not be called before completion of prepare() call.
	"""
	return null
