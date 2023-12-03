extends Resource
## Settings for [WFCMainThreadSolverRunner].
class_name WFCMainThreadRunnerSettings

## Max time to spend on solving the problem in each [member WFCMainThreadSolverRunner.update] call.
@export
var max_ms_per_frame: int = 10
