extends Resource
## Axis-aligned bounding box with integer corner coordinates
##
## Because Godot doesn't have one.
class_name WFCAABBi

## Corner with minimal coordinates on all axes, inclusive
@export
var mins: Vector3i

## Corner with maximal coordinates on all axes, inclusive
@export
var maxs: Vector3i

func _init() -> void:
	mins = Vector3i.MAX
	maxs = Vector3i.MIN

func expand(point: Vector3i) -> WFCAABBi:
	var res := WFCAABBi.new()
	res.mins = mins.min(point)
	res.maxs = maxs.max(point)
	return res

func position() -> Vector3i:
	return mins

func end() -> Vector3i:
	return maxs + Vector3i.ONE

func has_volume() -> bool:
	if mins.x > maxs.x:
		return false
	if mins.y > maxs.y:
		return false
	if mins.z > maxs.z:
		return false
	return true

func size() -> Vector3i:
	return Vector3i(maxi(0, 1 + maxs.x - mins.x), maxi(0, 1 + maxs.y - mins.y), maxi(0, 1 + maxs.y - mins.y))

func get_volume() -> int:
	var sz := size()
	return sz.x * sz.y * sz.z

func has_point(p: Vector3i) -> bool:
	return mins <= p and p <= maxs
