extends Resource

class_name WFCRules2D

@export
var mapper: Mapper2D

@export
var complete_matrices: bool = true

@export
var axes: Array[Vector2i] = [
	Vector2i(0, 1),
	Vector2i(1, 0)
]

@export
var axis_matrices: Array[BitMatrix] = []


func _learn_from(map: Node, positive: bool):
	var learning_rect: Rect2i = mapper.get_used_rect(map)

	for x in range(learning_rect.position.x, learning_rect.end.x):
		for y in range(learning_rect.position.y, learning_rect.end.y):
			var cell_coords: Vector2i = Vector2i(x, y)
			var cell: int = mapper.read_cell(map, cell_coords)
			
			if cell < 0:
				continue
			
			for a in range(axes.size()):
				var a_dir: Vector2i = axes[a]
				var other_cell: int = mapper.read_cell(
					map,
					cell_coords + a_dir,
				)
				if other_cell < 0:
					continue
				
				axis_matrices[a].set_bit(cell, other_cell, positive)

func learn_from(map: Node):
	assert(mapper != null)
	assert(mapper.supports_map(map))
	assert(mapper.size() > 1)
	assert(axes.size() > 0)
	assert(axis_matrices.is_empty() or axis_matrices.size() == axes.size())

	if axis_matrices.size() == 0:
		var num_cell_types: int = mapper.size()

		assert(num_cell_types > 1)

		for i in range(axes.size()):
			axis_matrices.append(BitMatrix.new(num_cell_types, num_cell_types))

	_learn_from(map, true)

	if complete_matrices:
		for mat in axis_matrices:
			mat.complete()


func learn_negative_from(map: Node):
	assert(mapper != null)
	assert(mapper.supports_map(map))
	assert(mapper.size() > 1)
	assert(axes.size() > 0)
	assert(axis_matrices.size() == axes.size())
	
	_learn_from(map, false)




















