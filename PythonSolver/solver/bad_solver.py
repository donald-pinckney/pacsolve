from typing import List, Optional
from program_ast.version import SemverVersion
from solver.base import Registry, Solver
from solver.solve_result import SolutionGraph, RootContextNode, ResolvedPackageNode
from program_ast.dependency import Dependency

class BadSolver(Solver):
  def solve(self, previous_solution: Optional[SolutionGraph], dependencies: List[Dependency], registry: Registry) -> SolutionGraph:
    root = RootContextNode()
    a = ResolvedPackageNode("a", SemverVersion(3, 2, 1))
    b = ResolvedPackageNode("b", SemverVersion(2, 1, 2))
    c = ResolvedPackageNode("c", SemverVersion(1, 2, 3))
    
    g = SolutionGraph(root, [a, b, c])
    g.add_edge(root, a)
    g.add_edge(root, c)
    g.add_edge(a, b)
    return g
    
    
    