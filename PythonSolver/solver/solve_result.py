from abc import ABC
from typing import Dict, List, Set, Union, cast
from program_ast.version import Version

class SolutionGraphNode(ABC):
  pass

class ResolvedPackageNode(SolutionGraphNode):
  def __init__(self, package: str, version: Version) -> None:
    super().__init__()
    self.package = package
    self.version = version
  
  def __members(self):
    return (self.package, self.version)

  def __eq__(self, other):
    if type(other) is type(self):
      return self.__members() == other.__members()
    else:
      return False

  def __hash__(self):
    return hash(self.__members())


class RootContextNode(SolutionGraphNode):
  def __init__(self) -> None:
    super().__init__()


class SolutionGraph(object):
  def __init__(self, context_node: RootContextNode, package_nodes: List[ResolvedPackageNode]) -> None:
    super().__init__()
    self.context_node = context_node
    self.package_nodes = package_nodes
    all_nodes: List[SolutionGraphNode] = cast(List[SolutionGraphNode], package_nodes) + [cast(SolutionGraphNode, context_node)]
    self.out_edges: Dict[SolutionGraphNode, Set[ResolvedPackageNode]] = {n: set() for n in all_nodes}

  def add_edge(self, from_node: SolutionGraphNode, to_node: ResolvedPackageNode):
    self.out_edges[from_node].add(to_node)
  
  def to_json(self):
    pass


class ExecutionResult(object):
  def __init__(self, is_success: bool, results_or_error: Union[List[SolutionGraph], str]) -> None:
    super().__init__()
    self.is_success = is_success
    self.results_or_error = results_or_error

  def to_json(self):
    pass


class SolveError(Exception):
  def __init__(self, message):
    self.message = message

  def to_json(self):
    pass