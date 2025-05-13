extends WFCMapper3D
class_name WFCGridMapMapper3D

## A [MeshLibrary] used by this mapper.
@export
var mesh_library: MeshLibrary

## Meta-attributes for meshes in [member mesh_library].
@export
var mesh_meta: Array[WFCMeshlibMeshMeta]

## Dictionary from tile attributes list to numeric tile id.
@export_storage
var attrs_to_id: Dictionary = {}

var _id_to_attrs: Array[Vector2i] = []

func _ensure_grid_map(node: Node) -> GridMap:
	assert(node is GridMap)

	return node as GridMap

func learn_from(map_: Node):
	var map := _ensure_grid_map(map_)

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

func get_used_rect(map_: Node) -> WFCAABBi:
	var map := _ensure_grid_map(map_)
	var res := WFCAABBi.new()
	
	for coord in map.get_used_cells():
		res = res.expand(coord)
	
	return res

func read_cell(map_: Node, coords: Vector3i) -> int:
	var map := _ensure_grid_map(map_)
	var attrs: Vector2i = Vector2i(
		map.get_cell_item(coords),
		map.get_cell_item_orientation(coords),
	)

	return attrs_to_id.get(attrs, -1)

func _ensure_reverse_mapping():
	if _id_to_attrs.size() == attrs_to_id.size():
		return

	_id_to_attrs.resize(attrs_to_id.size())

	for attrs in attrs_to_id.keys():
		_id_to_attrs[attrs_to_id[attrs]] = attrs

## See [method WFCMapper3D.read_tile_meta].
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

func write_cell(map_: Node, coords: Vector3i, code: int):
	assert(code < size())
	assert(mesh_library != null)

	var map: GridMap = _ensure_grid_map(map_)

	assert(map.mesh_library == mesh_library)

	_ensure_reverse_mapping()

	if code >= 0:
		var attrs: Vector2i = _id_to_attrs[code]
		map.set_cell_item(coords, attrs.x, attrs.y)
	else:
		map.set_cell_item(coords, -1)

func size() -> int:
	return attrs_to_id.size()

func supports_map(map: Node) -> bool:
	return map is GridMap

func clear():
	attrs_to_id.clear()
	_id_to_attrs.clear()
