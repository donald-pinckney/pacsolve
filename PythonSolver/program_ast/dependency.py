from .constraint import Constraint

############# DEPENDENCIES & WHOLE PROGRAMS #################
# A single dependency consists of the name of the package, and a constraint
class Dependency(object):
  def __init__(self, package_to_depend_on: str, constraint: Constraint) -> None:
    super().__init__()
    self.package_to_depend_on = package_to_depend_on
    self.constraint = constraint