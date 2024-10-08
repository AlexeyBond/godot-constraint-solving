# WFC (Wave Function Collapse) and generic constraint satisfaction problem solver implementation for Godot 4

![Screenshot of generated tile map](screenshots/2d-tilemap-0.png)

Features:
- **Backtracking** support.
  This addon implements backtracking, so it's possible to generate maps that are guaranteed to have no broken cells.
  However, it may take a lot more time (and more memory) so it's possible to disable backtracking or limit the number of attempts.
- **Multithreading**.
  Generation of a 2d map using WFC algorithm can be split into few tasks.
  Some of the tasks can be executed concurrently.
  The algorithm is (in most cases) able to detect if it's impossible to split the task.
  It falls back to single-threaded generation in such cases.
- **Learning from example**.
  2d WFC generator is able to infer rules from an example of a valid map.
  The algorithm also tries to infer some valid cell combinations beyond those provided in the example.
  In cases when the algorithm produces some invalid or not-nice-looking cell combinations, it's possible to also provide examples of cell combinations that should not appear in the final result.
  Or stop the generator from searching for additional cell combinations and provide all possible combinations in the initial example.
  Rules can also in some cases be learned from terrain settings of tilesets used in `TileMapLayer` maps.
- Supports **different node types**:
	- `TileMapLayer` and `TileMap` (including some **hexagonal** tilemaps, see [example](addons/wfc/examples/demo_wfc_2d_hex_tilemap.tscn))
	- `GridMap` (a flat map in one of XY/YZ/XZ planes can be generated)
	- Support of other node types can be added.
- Supports tile **probabilities**.
  Probabilities of specific tiles can be adjusted.
  In case of `TileMap(Layer)`, a builtin probability property or a custom data layer can be used.
  In case of `GridMap`, probability can be stored as metadate attribute of a mesh.
- **Not just WFC**.
  Addon contains a generic implementation of a solver capable of solving subclass of [constraint satisfaction problems](https://en.wikipedia.org/wiki/Constraint_satisfaction_problem) on top of which a WFC implementation is built.
  This generic solver can be reused for tasks different from WFC.

What's not (yet) implemented:
- 3d map generation.
  Generation of 3d maps (like `GridMap`s) is not yet implemented (but a 2D slice of a `GridMap` can be generated).
- Wrapping.
- Lazy/dynamic generation.
  For some games it may make sense to generate parts of level dynamically when they are (about to) become visible to player.
- Global constraints, including path constraints.
  It's not possible to generate a map that, for example, has all road tiles connected.
  However, it is [possible](#preconditions) to run a different algorithm before WFC to get some of effects that may be achieved using global constraints.
- Rules editor.
  Currently it's possible to "learn" WFC rules in running game only, not in editor.
  Rules can be edited by modifying sample maps, using standard editor tools.
  There is no special editor for WFC rules.
- Better demo/examples.
- Symmetry.
  In cases when a cell can be rotated (`GridMap`), the algorithm treats each combination of tile type and rotation as a separate tile type.
  So, you have to specify possible adjacent tiles for all rotations of each tile (in fact, just few are enough - the algorithm is able to infer other combinations automatically in most cases).

## Installing

This addon is [available in Godot Asset Library](https://godotengine.org/asset-library/asset/1951) and thus can be installed using editor's built-in addon manager.
Alternatievely, you can download an archive from [releases page](https://github.com/AlexeyBond/godot-constraint-solving/releases) or from current branch.

**Important:** in order to make `WFC2DGenerator` node available, you should enable the plugin in project settings after adding addon files to the project:
![Screenshot of project settings dialog with plugin enabled](screenshots/enable_plugin.png)

## How to use

### WFC2DGenerator node

The easiest way to use this addon to generate a map is by using a `WFC2DGenerator` node.

To do so follow the following steps:

1. Create (or use existing one) a tile set (if you're going to generate a 2d tile map) or mesh library (in case of a grid map).
2. Make a map (a `TileMapLayer` or `GridMap`) with examples of how your tiles should be used.
3. Create a `TileMapLayer` or `GridMap` generated map will be written to.
   The new map should use the same tile set/mesh library as one created on step 2.
   You may place some tiles on that map (either manually or procedurally), generator will take them into account and fill other cells accordingly.
   But try to not create an unsolvable puzzle when doing so.
4. Create a `WFC2DGenerator` node and set the following properties:
   - `target` should point to a map node that will contain a generated map - one created at step 3
   - `positive_sample` should point to a node that contains an example of a valid map - created at step 2
   - `rect` should contain a rect of target map that will be filled by generator
   - there are some other settings that may influence behavior and performance of the generator, feel free to experiment with those after you have a basic setup running
5. Run the generator.
   By default it will start as soon as a scene runs.
   However, you can clear `start_on_ready` flag and call `start()` method on generator node manually.
   For example, that can be useful if you fill some of cells in target map procedurally.

The resulting setup may look like the following:

![Example of WFC2DGenerator setup](screenshots/example-01.png)

Examples of such setups can be found in [examples](addons/wfc/examples) folder.

It may make sense to create and keep a minimal scene with generator, sample map and target map - just to ensure that samples are good enough to generate a good map with your tile set.

If some of tile combinations produced by generator don't look good - try adding a negative samples map and place those combinations there.

#### Preconditions

By default the generator will read exsting tiles from a map node it generates content for and will place other tiles to make them fit with existing ones.
This behavior makes it possible to combine WFC with other procedural generation algorithms (or manually pre-made level pieces): the previous algorithm may place some tiles and let WFC fill the remaining space.
However, this way it is only possible to specify the exact tile that should be placed in specific cell.
The preconditions API allows to limit possible cell contents in a more flexible way - by defining a set of tiles allowed in given cell.

The addon includes a [precondition](addons/wfc/problems/2d/preconditions/precondition_2d_dungeon.gd) ([example](addons/wfc/examples/demo_wfc_2d_tilemap_dungeon.tscn)) that generates a random set of connected road cells surrounded by wall cells a.k.a. a "dungeon".
The user can configure which tiles are "roads" and which are "walls" using custom data layers (in case of `TileMapLayer`s and `TileMap`s) or metadata (in case of `GridMap`s) of the tiles.
It isn't likely to fit specific needs of any actual game but it may serve as an example and/or starting point.

### Advanced use

`WFC2DGenerator` node is a high-level convenient wrapper for lower-level components.
In some cases it may be useful to use the low-level components directly.
See [sudoku demo](addons/wfc/examples/demo_sudoku.tscn) as an example.

You can extend different classes of this addon to achieve a desired behavior different from what is available by default.
For example, you can:
- add support for different map types by implementing your own [`WFCMapper2D`](addons/wfc/problems/2d/mappers/mapper_2d.gd) subclass
- add support of global constraints by extending [`WFC2DProblem`](addons/wfc/problems/2d/problem_wfc_2d.gd)
- use your own versions of internal components with the same interface as `WFC2DGenerator` by creating your own subclass of `WFC2DGenerator`

There is no detailed documentation (at least, for now) on how to use or extend internal components of the addon.
So please refer to source code to find a way to do what you need and feel free to ask questions in [github issues](https://github.com/AlexeyBond/godot-constraint-solving/issues).

## Copyright notes

This addon is licenced under MIT licence.

Examples/demos use assets (["tiny dungeon" tileset](addons/wfc/examples/assets/kenney-tiny-dungeon), ["Pixel Shmup" tileset](https://www.kenney.nl/assets/pixel-shmup), ["nature kit" models pack](addons/wfc/examples/assets/kenny-nature-kit)) from [Kenney](https://kenney.nl/).
Hexagonal tilemap example [uses](addons/wfc/examples/assets/Underearth) ["Underearth Hex Dungeon" tile set](https://opengameart.org/content/underearth-hex-dungeon). 

This addon uses [GUT](https://github.com/bitwes/Gut) for unit testing (not included in downloadable archive).

The [logo](./icon.png) is generated using Stable Diffusion.
