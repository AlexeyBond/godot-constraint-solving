extends Resource
class_name WFC2DPrecondition2DNullSettings

"""
Contains serializable settings for creation of a WFC2DPrecondition.

This base class creates an empty precondition that does not limit acontent of any cells.
For custom precondition classes a corresponding WFC2DPrecondition2DNullSettings subclasses should exist.

This class is named WFC2DPrecondition2DNullSettings, not WFC2DPrecondition2DSettings to make it clearer to
node inspector users that it will create a "null" (empty, default) precondition.
If GdScript supported interfaces or abstract classes then there would be an interface/abstract class
IWFC2DPrecondition2DSettings and WFC2DPrecondition2DNullSettings extending/implementing it along with
other concreate classes.
But with GdScript all other precondition settings classes should extend WFC2DPrecondition2DNullSettings.
"""

class CreationParameters:
	var problem_settings: WFC2DProblem.WFC2DProblemSettings
	var target_node: Node
	var generator_node: WFC2DGenerator

func create_precondition(parameters: CreationParameters) -> WFC2DPrecondition:
	"""
	Instantiates a precondition using settings from this object.
	"""
	return WFC2DPrecondition.new()
