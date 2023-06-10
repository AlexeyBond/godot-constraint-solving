# WFC (Wave Function Collapse) and generic constraint-solving implementation for Godot 4

Features:
- **Backtracking** support.
  This addon implements backtracking, so it's possible to generate maps that are guaranteed to have no broken cells.
  However, it may take a lot more time (and more memory) so it's possible to disable backtracking or limit the number of attemts.
- **Multithreading**.
  Generation of a 2d map using WFC algorithm can be split into few tasks.
  Some of the tasks can be executed concurrently.
  The algorithm is able to detect cases when it's impossible to split the task and fallback to single-threaded generation in such cases.
- Supports **different node types**:
	- `TileMap`
	- `GridMap` (a flat map in one of XY/YZ/XZ planes can be generated)
	- Support of other node types can be added.
- **Not just WFC**.
  Addon contains a generic implementation of a constraint-solving algorithm on top of which a WFC algorithm is built.
  This generic algorithm implementation can be reused for tasks different from WFC.
