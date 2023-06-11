# WFC (Wave Function Collapse) and generic constraint-solving implementation for Godot 4

![Screenshot of generated tile map](screenshots/2d-tilemap-0.png)

Features:
- **Backtracking** support.
  This addon implements backtracking, so it's possible to generate maps that are guaranteed to have no broken cells.
  However, it may take a lot more time (and more memory) so it's possible to disable backtracking or limit the number of attemts.
- **Multithreading**.
  Generation of a 2d map using WFC algorithm can be split into few tasks.
  Some of the tasks can be executed concurrently.
  The algorithm is able to detect cases when it's impossible to split the task and fallback to single-threaded generation in such cases.
- **Learning from example**.
  2d WFC generator is able to infer rules from an example of a valid map.
  The algorithm also tries to infer some valid cell combinations beyond those provided in the example.
  In cases when algorithm produces some invalid or not-nice-looking cell combinations, it's possible to also provide examples of cell combinations that should not appear in the final result.
  Or stop the generator from searching for additional cell combinations and provide all possible combinations in the initial example.
- Supports **different node types**:
	- `TileMap`
	- `GridMap` (a flat map in one of XY/YZ/XZ planes can be generated)
	- Support of other node types can be added.
- **Not just WFC**.
  Addon contains a generic implementation of a constraint-solving algorithm on top of which a WFC algorithm is built.
  This generic algorithm implementation can be reused for tasks different from WFC.

What's not (yet) implemented:
- 3d map generation.
  Generation of 3d maps (for `GridMap`s or multi-layered `TileMap`s) is not yet implemented.
- Tile probabilities.
  It's currently not possible to control probabilities of certain tile types being "observed".
- Rules editor.
  Currently it's possible to "learn" WFC rules in running game only, not in editor.
  Rules can be edited by modifying sample maps, using standard editor tools.
  There is no special editor for WFC rules.
- Better demo/examples.
- Symmetry.
  In cases when a cell can be rotated (`GridMap`), the algorithm treats each combination of tile type and rotation as a separate tile type.
  So, you have to specify possible adjacent tiles for all rotations of each tile (in fact, just few are enough - the algorithm is able to infer other combinations automatically in most cases).


## Copyright notes

This addon is licenced under MIT licence.

Examples/demos use [assets](https://github.com/AlexeyBond/godot-constraint-solving/tree/master/addons/wfc/examples/assets) from [Kenney](https://kenney.nl/).

This addon uses [GUT](https://github.com/bitwes/Gut) for unit testing (not included in downloadable archive).
