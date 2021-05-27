from abc import ABC, abstractmethod
from typing import Any, Dict, List, Set, Union, cast
from program_ast.version import Version

class SolutionGraphVertex(ABC):
  @abstractmethod
  def to_json(self) -> Any:
    pass
  
class ResolvedPackageVertex(SolutionGraphVertex):
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

  def to_json(self) -> Any:
    return {'resolved_package_vertex': {'package': self.package, 'vertex': self.version.to_json()}}


class RootContextVertex(SolutionGraphVertex):
  def __init__(self) -> None:
    super().__init__()

  def to_json(self) -> Any:
    return {'root_context_vertex': None}


class SolutionGraph(object):
  def __init__(self, context_vertex: RootContextVertex, package_vertices: List[ResolvedPackageVertex]) -> None:
    super().__init__()
    self.context_vertex = context_vertex
    self.package_vertices = set(package_vertices)
    self.all_vertices = set(cast(List[SolutionGraphVertex], package_vertices))
    self.all_vertices.add(context_vertex)
    self.out_edges: Dict[SolutionGraphVertex, Set[SolutionGraphVertex]] = {n: set() for n in self.all_vertices}

  def add_edge(self, from_vertex: SolutionGraphVertex, to_vertex: SolutionGraphVertex):
    assert from_vertex in self.all_vertices
    assert to_vertex in self.all_vertices
    self.out_edges[from_vertex].add(to_vertex)
  
  def to_json(self):
    return {
      'context_vertex': self.context_vertex.to_json(), 
      'package_vertices': [p.to_json() for p in self.package_vertices], 
      'adjacency_lists': [{'source_vertex': k.to_json(), 'out_edges': [ov.to_json() for ov in outs]} for k, outs in self.out_edges.items()]
    }


class ExecutionResult(object):
  def __init__(self, is_success: bool, results_or_error: Union[List[SolutionGraph], str]) -> None:
    super().__init__()
    self.is_success = is_success
    self.results_or_error = results_or_error

  def to_json(self):
    if self.is_success:
      return {'result_success': [cast(SolutionGraph, g).to_json() for g in self.results_or_error]}
    else:
      return {'result_failure': self.results_or_error}


class SolveError(Exception):
  def __init__(self, message):
    self.message = message

  def to_json(self):
    pass