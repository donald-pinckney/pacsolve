from typing import Dict, Optional, Set, Tuple
from abc import ABC, abstractmethod
from program_ast.dependency import Dependency
from solver.solve_result import *
from program_ast.program import Program

Registry = Dict[Tuple[str, Version], List[Dependency]]

class WorldState(object):
  def __init__(self, contexts: Set[str]) -> None:
    super().__init__()
    self.registry: Registry = dict()
    self.context_results: Dict[str, Optional[SolutionGraph]] = {ctx: None for ctx in contexts}

  def publish(self, package: str, version: Version, dependencies: List[Dependency]):
    if (package, version) in self.registry:
      raise ValueError
    else:
      self.registry[(package, version)] = dependencies

  def get_registry(self) -> Registry:
    return self.registry

  def yank(self, package: str, version: Version):
    del self.registry[(package, version)]

  def get_context_result(self, context: str) -> Optional[SolutionGraph]:
    return self.context_results[context]

  def set_context_result(self, context: str, result: SolutionGraph):
    self.context_results[context] = result

class Solver(ABC):
  # Should raise a SolveError exception if dependencies can't be solved.
  @abstractmethod
  def solve(self, previous_solution: Optional[SolutionGraph], dependencies: List[Dependency], registry: Registry) -> SolutionGraph:
    pass

  def run_program(self, program: Program) -> ExecutionResult:
    world = WorldState(program.contexts)
    results = []
    for op in program.ops:
      # 3 cases: 1) run raises exception: publish/yank/solve error, abort now
      #          2) run returns None: execution ok, but does not save a result (publish/yank)
      #          3) run returns non-None: save this result in the list (solve)
      try:
        r = op.run(self, world)
      except Exception as err:
        return ExecutionResult(False, str(err))

      if r is not None:
        results.append(r)
    
    return ExecutionResult(True, results)