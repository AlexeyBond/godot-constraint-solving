extends GutTest

func test_solve_sudoku():
	var problem: WFCProblem = WFCSudokuProblem.new(9,9,9)
	var solver: WFCSolver = WFCSolver.new(problem)
	
	solver.allow_backtracking = true
	solver.solve()
	
	for row in range(9):
		var arr: Array = []
		
		for col in range(9):
			arr.append(solver.current_state.cell_solution_or_entropy[problem.coords_to_id(row, col)])
		
		arr.sort()
		
		assert_eq_deep(
			arr,
			[0,1,2,3,4,5,6,7,8]
		)
	for col in range(9):
		var arr: Array = []
		
		for row in range(9):
			arr.append(solver.current_state.cell_solution_or_entropy[problem.coords_to_id(row, col)])
		
		arr.sort()
		
		assert_eq_deep(
			arr,
			[0,1,2,3,4,5,6,7,8]
		)
