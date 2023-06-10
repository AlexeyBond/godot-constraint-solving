extends Resource

class_name WFCMultithreadedRunnerSettings

@export
var max_threads: int = -1

func get_max_threads() -> int:
	if max_threads < 1:
		max_threads = clamp(OS.get_processor_count() - 1, 1, 4)
	
	return max_threads
