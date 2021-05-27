from typing import List, Union
from program_ast.version import Version


class ResolvedPackage(object):
  def __init__(self, package: str, version: Version, children: List["ResolvedPackage"]) -> None:
    super().__init__()
    self.package = package
    self.version = version
    self.children = children

  def to_json(self):
      pass


class SolutionTree(object):
  def __init__(self, children: List[ResolvedPackage]) -> None:
    super().__init__()
    self.children = children
  
  def to_json(self):
    pass


class ExecutionResult(object):
  def __init__(self, is_success: bool, results_or_error: Union[List[SolutionTree], str]) -> None:
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