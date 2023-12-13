extends Resource
## Meta attribute for a mesh in [MeshLibrary].
class_name WFCMeshlibMeshMeta

## Name of a mesh this attribute belongs to.
@export
var mesh_name: String

## Name of the attribute.
@export
var meta_name: String

## Value(s) of the attribute.
## [br]
## This is an array because Godot 4.2 does not allow to export a variable of type [Variant].
@export
var meta_values: Array
