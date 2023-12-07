class_name WFC2DPrecondition
## Sets initial conditions for 2D WFC generation.
##
## Preconditions can be used to integrate WFC algorithm with other procedural generation algorithms.
## For example, [WFC2DPreconditionDungeon] generates a set of interconnected rooms and tunnels.
## But, instead of just writing tiles to tilemap, it decides what cells should be passable and what
## should not.
## And then lets WFC fill the map allowing only certain tiles in cells that should be definitely
## passable or definitely not passable.
## [br]
## Instances of [WFC2DPrecondition] should be created by
## [WFC2DPrecondition2DNullSettings] subclasses.
extends RefCounted

## Initialize this precondition.
## [br]
## Must be called at most once on one object.
func prepare():
	pass

## Returns initial domain of a cell at given coordinates.
## [br]
## Returns null if this precondition doesn't limit domain of cell at given coordinates.
## [br]
## Must not be called before completion of prepare() call.
func read_domain(coords: Vector2i) -> WFCBitSet:
	return null
