from .version import Version
from .dependency import Dependency
from typing import List

# The base class for the different types of program operations
class Op(object):
  def __init__(self) -> None:
    super().__init__()

# A publish operation
class OpPublish(Op):
  def __init__(self, package: str, version: Version, dependencies: List[Dependency]) -> None:
    super().__init__()
    self.package = package
    self.version = version
    self.dependencies = dependencies

# A yank operation
class OpYank(Op):
  def __init__(self, package: str, version: Version) -> None:
    super().__init__()
    self.package = package
    self.version = version

# A solve operation
class OpSolve(Op):
  def __init__(self, in_context: str, dependencies: List[Dependency]) -> None:
    super().__init__()
    self.in_context = in_context
    self.dependencies = dependencies