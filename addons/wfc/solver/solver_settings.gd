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
