from .version import Version
from .dependency import Dependency
from solver.solve_result import SolutionGraph
from typing import List, Optional, Set
from abc import ABC, abstractmethod

# The base class for the different types of program operations
class Op(ABC):
  def __init__(self) -> None:
    super().__init__()

  @abstractmethod
  def run(self, solver, world_state) -> Optional[SolutionGraph]:
    pass

# A publish operation
class OpPublish(Op):
  def __init__(self, package: str, version: Version, dependencies: List[Dependency]) -> None:
    super().__init__()
    self.package = package
    self.version = version
    self.dependencies = dependencies

  def run(self, solver, world_state) -> Optional[SolutionGraph]:
    world_state.publish(self.package, self.version, self.dependencies)

# A yank operation
class OpYank(Op):
  def __init__(self, package: str, version: Version) -> None:
    super().__init__()
    self.package = package
    self.version = version

  def run(self, solver, world_state) -> Optional[SolutionGraph]:
    world_state.yank(self.package, self.version)

# A solve operation
class OpSolve(Op):
  def __init__(self, in_context: str, dependencies: List[Dependency]) -> None:
    super().__init__()
    self.in_context = in_context
    self.dependencies = dependencies

  def run(self, solver, world_state) -> Optional[SolutionGraph]:
    result = solver.solve(world_state.get_context_result(self.in_context), self.dependencies, world_state.get_registry())
    world_state.set_context_result(self.in_context, result)
    return result


class Program(object):
  def __init__(self, contexts: Set[str], ops: List[Op]) -> None:
    super().__init__()
    self.contexts = contexts
    self.ops = ops