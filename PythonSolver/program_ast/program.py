from .version import VersionFormat
from .op import Op
from typing import List, Set


class Program(object):
  def __init__(self, version_format: VersionFormat, contexts: Set[str], ops: List[Op]) -> None:
    super().__init__()
    self.contexts = contexts
    self.ops = ops
