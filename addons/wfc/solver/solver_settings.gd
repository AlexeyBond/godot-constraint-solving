extends Resource
## Settings for [WFCSolver].
##
## Contains serializable settings for [WFCSolver].
## [br]
## Mostly defines how a solver uses backtracking.
class_name WFCSolverSettings

## Enable to allow solver to use backtracking.
## [br]
## When disabled, solver will not use backtracking and other backtracking-related
## settings will be ignored.
@export
var allow_backtracking: bool = true

## When enabled, solver will not try to search for incomplete solution if backtracking fails.
@export
var require_backtracking: bool = false

## How many times a solver will try to backtrack before giving up and starting to search for an
## incomplete solution.
## [br]
## When set to [code]0[/code] or negative value, the solver will backtrack as much as possible,
## in worst case brute-forcing all possible cell configurations.
@export
var backtracking_limit: int = -1

## Number of "observations" after which some of intermediate states will not be stored even when
## backtracking is enabled.
## [br]
## When set to [code]0[/code] or less - all intermediate states will be stored if backtracking is
## enabled.
## [br]
## Skipping some intermediate states will reduce memory usage during solution but will randomly
## affect amount of time required to solve the problem.
@export
var sparse_history_start: int = 10

## Number of intermediate states skipped when [member sparse_history_start] is activated.
## [br]
## When [member sparse_history_interval] is set to [code]N[/code], only every [code]N[/code]'th
## intermediate state will be stored, and thus, the memory consumption by algorithm will be reduced
## [code]N[/code] times.
## However, when backtracking happens, the solver will revert multiple (from 1 to [code]N[/code])
## observations - until the last saved state.
## In case of problems with high probability of backtracking this may increase time required to
## solve the problem, or even meke the solver unable to solve it at all.
@export
var sparse_history_interval: int = 10

func is_sparse_history_enabled():
	return sparse_history_start > 0

## Forces use of AC3-like constraint propagation algorithm.
## [br]
## When disabled, the solver will use an AC4-like algorithm if possible.
## [br]
## [color=red]Current implementation of AC4-like algorithm is less stable and, suddenly, less
## efficient in some cases[/color] (but it is more efficient in some other cases as well), so this
## option is marked as experimental and enabled by default.
## [br]
## Experimental mark will be removed and default value will be changed when/if the issue with low
## performance will be fixed and all edge-cases will be covered.
## @experimental
@export
var force_ac3: bool = true
