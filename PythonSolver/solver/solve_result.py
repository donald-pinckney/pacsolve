from abc import ABC, abstractmethod
from typing import Any, Dict, List, Set, Union, cast
from program_ast.version import Version, VersionFormat

class SolutionGraphVertex(ABC):
  @abstractmethod
  def to_json(self) -> Any:
    pass
  
class ResolvedPackageVertex(SolutionGraphVertex):
  def __init__(self, package: str, version: Version) -> None:
    super().__init__()
    self.package = package
    self.version = version

  def to_json(self) -> Any:
    return {'resolved_package_vertex': {'package': self.package, 'version': self.version.to_json(), 'data': {}}}


class RootContextVertex(SolutionGraphVertex):
  def __init__(self) -> None:
    super().__init__()

  def to_json(self) -> Any:
    return {'root_context_vertex': None}


class SolutionGraph(object):
  def __init__(self, vertices=[RootContextVertex()], context_vertex=0, out_edges: Dict[int, List[int]]=dict()) -> None:
    super().__init__()
    self.vertices: List = vertices
    self.context_vertex = context_vertex
    self.out_edges = {v: (out_edges[v] if v in out_edges else []) for v in range(len(vertices))}

  def add_edge(self, from_vertex: int, to_vertex: int):
    self.out_edges[from_vertex].append(to_vertex)

  def add_context_edge(self, to_vertex: int):
    self.add_edge(self.context_vertex, to_vertex)

  def add_vertex(self, v: SolutionGraphVertex) -> int:
    idx = len(self.vertices)
    assert idx not in self.out_edges

    self.vertices.append(v)
    self.out_edges[idx] = []
    return idx
  
  def to_json(self):
    return {
      'vertices': [v.to_json() for v in self.vertices],
      'contextVertex': self.context_vertex,
      'adjacencyLists': self.out_edges,
    }


class ExecutionResult(object):
  def __init__(self, is_success: bool, results_or_error: Union[List[SolutionGraph], str]) -> None:
    super().__init__()
    self.is_success = is_success
    self.results_or_error = results_or_error

  def to_json(self, version_format: VersionFormat):
    if self.is_success:
      return {'result_success': {'versionFormat': version_format.to_json(), 'results': [cast(SolutionGraph, g).to_json() for g in self.results_or_error]}}
    else:
      return {'result_failure': self.results_or_error}


class SolveError(Exception):
  def __init__(self, message):
    self.message = message

  def to_json(self):
    pass