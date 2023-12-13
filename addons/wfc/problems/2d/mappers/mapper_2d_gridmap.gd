extends WFCMapper2D
## A [WFCMapper2D] for [GridMap]s.
##
## Works with a slice of a [GridMap] as a 2D map.
## The slice should be parallel to one of base planes (XY, YZ, XZ).
## The plane is chosen by [member x_axis], [member y_axis] and [member unused_axis].
## Offset from center is set by [member base_point].
class_name WFCGridMapMapper2D

## Coordinates of the cell that will be assumed to be at coordinates [code](0,0)[/code].
@export
var base_point: Vector3i = Vector3i(0, 0, 0)

## A [MeshLibrary] used by this mapper.
@export
var mesh_library: MeshLibrary

## Meta-attributes for meshes in [member mesh_library].
@export
var mesh_meta: Array[WFCMeshlibMeshMeta]

## An axis that will be used as X axis for all cell access operations.
@export_enum("X", "Y", "Z")
var x_axis: int = Vector3i.AXIS_X

## An axis that will be used as Y axis for all cell access operations.
@export_enum("X", "Y", "Z")
var y_axis: int = Vector3i.AXIS_Z

## The third axis, orthogonal to [member x_axis] and [member y_axis].
@export_enum("X", "Y", "Z")
var unused_axis: int = Vector3i.AXIS_Y

## Dictionary from tile attributes list to numeric tile id.
## [br]
## [color=red]Do not modify manually[/color].
@export
var attrs_to_id: Dictionary = {}

var _id_to_attrs: Array[Vector2i] = []

func _map_to_2d(map_coords: Vector3i) -> Vector3i:
	assert(x_axis != y_axis)
	assert(x_axis != unused_axis)
	assert(y_axis != unused_axis)

	map_coords -= base_point
	return Vector3i(map_coords[x_axis], map_coords[y_axis], map_coords[unused_axis])

func _2d_to_map(coords: Vector2i) -> Vector3i:
	var res: Vector3i = Vector3i.ZERO

	res[x_axis] = coords.x
	res[y_axis] = coords.y

	return res + base_point

func _ensure_grid_map(node: Node) -> GridMap:
	assert(node is GridMap)

	return node as GridMap

## See [method WFCMapper2D.learn_from].
func learn_from(map_: Node):
	var map: GridMap = _ensure_grid_map(map_)

	if mesh_library == null:
		mesh_library = map.mesh_library

	assert(mesh_library == map.mesh_library)

	for used_coord in map.get_used_cells():
		var mesh_id: int = map.get_cell_item(used_coord)
		var orientation: int = map.get_cell_item_orientation(used_coord)

		var attrs: Vector2i = Vector2i(mesh_id, orientation)

		if attrs in attrs_to_id:
			continue

		attrs_to_id[attrs] = len(attrs_to_id)

## See [method WFCMapper2D.get_used_rect].
func get_used_rect(map_: Node) -> Rect2i:
	var map: GridMap = _ensure_grid_map(map_)
	var res: Rect2i

	for used_coord in map.get_used_cells():
		var mapped_coord: Vector3i = _map_to_2d(used_coord)

		if mapped_coord.z != 0:
			continue

		var c: Vector2i = Vector2i(mapped_coord.x, mapped_coord.y)

		if res.has_area():
			res = res.expand(c)
		else:
			res.position = c
			res.size = Vector2i(1, 1)

	return res

## See [method WFCMapper2D.read_cell].
func read_cell(map_: Node, coords: Vector2i) -> int:
	var map: GridMap = _ensure_grid_map(map_)
	var c: Vector3i = _2d_to_map(coords)

	var attrs: Vector2i = Vector2i(
		map.get_cell_item(c),
		map.get_cell_item_orientation(c),
	)

	return attrs_to_id.get(attrs, -1)

func _ensure_reverse_mapping():
	if _id_to_attrs.size() == attrs_to_id.size():
		return

	_id_to_attrs.resize(attrs_to_id.size())

	for attrs in attrs_to_id.keys():
		_id_to_attrs[attrs_to_id[attrs]] = attrs

## See [method WFCMapper2D.read_tile_meta].
## [br]
## Currently (Godot 4.2) there is no way to specify metadata for meshes in meshlib.
## So, this method uses [member mesh_meta].
func read_tile_meta(tile: int, meta_name: String) -> Array:
	if tile < 0:
		return []

	_ensure_reverse_mapping()
	assert(tile < _id_to_attrs.size())

	var attrs := _id_to_attrs[tile]

	var mesh_name := mesh_library.get_item_name(attrs.x)
	var result := []

	for meta in mesh_meta:
		if meta.mesh_name == mesh_name and meta.meta_name == meta_name:
			result.append_array(meta.meta_values)

	return result

## See [method WFCMapper2D.write_cell].
func write_cell(map_: Node, coords: Vector2i, code: int):
	assert(code < size())
	assert(mesh_library != null)

	var map: GridMap = _ensure_grid_map(map_)

	assert(map.mesh_library == mesh_library)

	_ensure_reverse_mapping()

	var map_coords: Vector3i = _2d_to_map(coords)

	if code >= 0:
		var attrs: Vector2i = _id_to_attrs[code]
		map.set_cell_item(map_coords, attrs.x, attrs.y)
	else:
		map.set_cell_item(map_coords, -1)

## See [method WFCMapper2D.size].
func size() -> int:
	return attrs_to_id.size()

## See [method WFCMapper2D.supports_map].
func supports_map(map: Node) -> bool:
	return map is GridMap

## See [method WFCMapper2D.clear].
func clear():
	_id_to_attrs.clear()
	attrs_to_id.clear()
