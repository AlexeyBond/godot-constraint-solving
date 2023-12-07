extends WFC2DPrecondition2DNullSettings
## Settings for a precondition that generates a dungeon-like structure.
class_name WFC2DPreconditionDungeonSettings

## Minimal size of walls between a non-wall area and border of WFC-generated area.
@export
var wall_border_size: Vector2i = Vector2i(1, 2)

## Size of unconstrained gaps between roads and walls.
## [br]
## This setting may require some careful balancing.
## Too small value may lead to WFC failures and very rectangular rooms.
## Too big value may generate disconnected rooms within gaps between walls and roads.
@export
var free_gap: Vector2i = Vector2i(2, 2)

## Base half-size of rooms.
@export
var room_half_size_base: Vector2i = Vector2i(2, 2)

## How much half-size of the rooms can be changed randomly.
## [br]
## Room sizes will be between
## [code]room_half_size_base - room_half_size_variation[/code] and
## [code]room_half_size_base + room_half_size_variation[/code].
@export
var room_half_size_variation: Vector2i = Vector2i(2, 2)

## Probability of a room being generated at turn/fork of a corridor.
@export_range(0.0001, 1.0)
var room_probability: float = 0.5

## Base length of straight corridor segments.
@export
var road_len_base: int = 15

## How much a length of a straight corridor segment may change.
@export
var road_len_variation: int = 5

## Probability of a fork in a corridor.
## [br]
## Corridors may fork between straight segments.
@export_range(0.0001, 1.0)
var fork_probability: float = 0.5

## Probability of a fork becoming a full crossroads.
@export_range(0.0001, 1.0)
var full_fork_probability: float = 0.5

## How much of the area should be filled with passable cells.
## [br]
## [b]Note:[/b] this does not include gaps controlled by [member free_gap], so actual ratio of
## passable area will in most cases be higher than this.
@export_range(0.0001, 1.0)
var passable_area_ratio: float = 0.1

## Max. number of iterations to perform.
## [br]
## This is mostly a safety check to avoid infinite loop.
@export
var iterations_limit: int = 1000

## Name of meta attribute/custom data layer that marks passable tiles.
@export
var road_class: String = "wfc_dungeon_road"

## Name of meta attribute/custom data layer that marks wall tiles.
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
