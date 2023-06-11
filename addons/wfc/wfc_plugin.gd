@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type(
		"WFC2DGenerator", "Node",
		preload("nodes/generator_2d.gd"),
		preload("nodes/generator_2d_icon.png"),
)

func _exit_tree():
	remove_custom_type("WFC2DGenerator")
