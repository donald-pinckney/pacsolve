from typing import List, Optional
from program_ast.version import SemverVersion
from solver.base import Registry, Solver
from solver.solve_result import ResolvedPackage, SolutionTree
from program_ast.dependency import Dependency

class BadSolver(Solver):
  def solve(self, previous_solution: Optional[SolutionTree], dependencies: List[Dependency], registry: Registry) -> SolutionTree:
    return SolutionTree([
      ResolvedPackage("a", SemverVersion(3, 2, 1), [
        ResolvedPackage("b", SemverVersion(2, 1, 2), [])]), 
      ResolvedPackage("c", SemverVersion(1, 2, 3), [])
    ])