extends WFC2DPrecondition2DNullSettings
class_name WFC2DPreconditionDungeonSettings

@export
var wall_border_size: Vector2i = Vector2i(1, 2)

@export
var free_gap: Vector2i = Vector2i(2, 2)

@export
var room_half_size_base: Vector2i = Vector2i(2, 2)

@export
var room_half_size_variation: Vector2i = Vector2i(2, 2)

@export_range(0.0001, 1.0)
var room_probability: float = 0.5

@export
var road_len_base: int = 15

@export
var road_len_variation: int = 5

@export_range(0.0001, 1.0)
var fork_probability: float = 0.5

@export_range(0.0001, 1.0)
var full_fork_probability: float = 0.5

@export_range(0.0001, 1.0)
var passable_area_ratio: float = 0.1

@export
var iterations_limit: int = 1000

@export
var road_class: String = "wfc_dungeon_road"

@export
var wall_class: String = "wfc_dungeon_wall"

func create_precondition(parameters: WFC2DPrecondition2DNullSettings.CreationParameters) -> WFC2DPrecondition:
	var res: WFC2DPreconditionDungeon = WFC2DPreconditionDungeon.new()

	res.rect = parameters.problem_settings.rect

	res.learn_classes(parameters.problem_settings.rules.mapper, road_class, wall_class)

	assert(wall_border_size >= Vector2i.ZERO)
	res.wall_border_size = wall_border_size

	assert(free_gap >= Vector2i.ZERO)
	res.free_gap = free_gap

	assert(room_half_size_base > Vector2i.ZERO)
	res.room_half_size_base = room_half_size_base

	assert(room_half_size_variation > Vector2i.ZERO)
	assert(room_half_size_variation <= room_half_size_variation)
	res.room_half_size_variation = room_half_size_variation

	res.room_probability = room_probability

	assert(road_len_base > 0)
	res.road_len_base = road_len_base

	assert(road_len_variation > 0)
	assert(road_len_variation < road_len_base)
	res.road_len_variation = road_len_variation

	res.fork_probability = fork_probability
	res.full_fork_probability = full_fork_probability
	res.passable_area_ratio = passable_area_ratio

	assert(iterations_limit > 0)
	res.iterations_limit = iterations_limit

	return res

