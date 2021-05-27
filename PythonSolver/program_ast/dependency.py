from .constraint import Constraint


class Dependency(object):
  def __init__(self, package_to_depend_on: str, constraint: Constraint) -> None:
    super().__init__()
    self.package_to_depend_on = package_to_depend_on
    self.constraint = constraint