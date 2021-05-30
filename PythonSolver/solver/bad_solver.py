from typing import List, Optional
from program_ast.version import SemverVersion
from solver.base import Registry, Solver
from solver.solve_result import SolutionGraph, RootContextVertex, ResolvedPackageVertex, SolveError
from program_ast.dependency import Dependency

class BadSolver(Solver):
  def solve(self, previous_solution: Optional[SolutionGraph], dependencies: List[Dependency], registry: Registry) -> SolutionGraph:
    root = RootContextVertex()
    a = ResolvedPackageVertex("a", SemverVersion(3, 2, 1))
    b = ResolvedPackageVertex("b", SemverVersion(2, 1, 2))
    c = ResolvedPackageVertex("c", SemverVersion(1, 2, 3))
    
    g = SolutionGraph(
      vertices=[root, a, b, c], 
      context_vertex=0, 
      out_edges={0: [1, 3], 1: [2]})
    return g
    
    
    