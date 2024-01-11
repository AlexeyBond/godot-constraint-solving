extends Resource
## Mapper for 2D WFC
##
## The name [b]mapper[/b] describes two functions of this class:
## it provides an interface between the algorithm and a [b]map[/b] node and
## [b]map[/b]s tiles from format specific for certain map type to (and from) numbers used by the WFC
## algorithm.
## [br]
## Mapper allows the algorithm to access a map node as something like a 2D-array of numbers.
class_name WFCMapper2D

## Learn tile types from given map node.
func learn_from(_map: Node):
	@warning_ignore("assert_always_false")
	assert(false)

## Returns rect of target map that contains all non-empty cells.
func get_used_rect(_map: Node) -> Rect2i:
	@warning_ignore("assert_always_false")
	assert(false)
	return Rect2i()

## Read cell from map and return a mapped code.
## [br]
## Returns a negative value if cell is empty or mapping for the cell is missing.
func read_cell(_map: Node, _coords: Vector2i) -> int:
	@warning_ignore("assert_always_false")
	assert(false)
	return -1

## Read metadata attribute values associated with given cell type.
## [br]
## May return array of multiple values if cell type consists of multiple objects having metadata.
## E.g. combinations of different tiles in multi-layer tilemap.
func read_tile_meta(_tile: int, _meta_name: String) -> Array:
	@warning_ignore("assert_always_false")
	assert(false)
	return []

## Reads meta of given tile (see [method read_tile_meta]) and converts it to a single boolean value.
## [br]
## Returns [code]true[/code] iff there is at least one truthy meta value.
func read_tile_meta_boolean(tile: int, meta_name: String) -> bool:
	for v in read_tile_meta(tile, meta_name):
		if v:
			return true

	return false

## Name of a metadata attribute/custom data layer (as interpreted by [method read_tile_meta]) used
## to read tile probabilities.
@export
var probability_meta_key: String = "wfc_probability"

## Read probability value assigned to given tile type.
## [br]
## By default uses values from metadata attribute using name from probability_meta_key property.
## Sub-classes may override this behavior.
func read_tile_probability(tile: int) -> float:
	if tile < 0:
		return 0.0
	assert(tile < size())

	var probability := 1.0

	for p in read_tile_meta(tile, probability_meta_key):
		probability *= p

	return probability

## Write a cell to map.
## [br]
## [param _code] should be inside acceptable range for mapped codes.
func write_cell(_map: Node, _coords: Vector2i, _code: int):
	@warning_ignore("assert_always_false")
	assert(false)

## Returns number of cell types known by the mapper.
func size() -> int:
	@warning_ignore("assert_always_false")
	assert(false)
	return 0

## Check if this mapper is capable of working with given map node.
func supports_map(_map: Node) -> bool:
	@warning_ignore("assert_always_false")
	assert(false)
	return false

## Reset state (everything learned in [method learn_from] calls) of this mapper.
func clear():
	@warning_ignore("assert_always_false")
	assert(false)

## Return true if this mapper is ready to read/write a map.
func is_ready() -> bool:
	return size() > 0
