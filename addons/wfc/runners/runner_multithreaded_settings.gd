extends Resource
## Settings for [code]WFCMultithreadedSolverRunner[/code].
##
## See [WFCMultithreadedSolverRunner].
class_name WFCMultithreadedRunnerSettings

## Maximum number of threads used when number of threads is calculated based on number of available
## CPU cores.
const MAX_AUTO_THREADS := 4

## Maximum number of threads to use.
## [br]
## When set to non-positive value (default) the number of threads will be chosen based on number of
## available CPU cores, but not larger than [constant MAX_AUTO_THREADS].
## [br]
## When set to [code]1[/code], the runner will always run a single solver in single [Thread].
## Such mode is potentially most efficient and safe, but slower than real multithreading.
@export
var max_threads: int = -1

## Calculates actual number of allowed threads.
func get_max_threads() -> int:
	if max_threads < 1:
		max_threads = clamp(OS.get_processor_count() - 1, 1, MAX_AUTO_THREADS)

	return max_threads
