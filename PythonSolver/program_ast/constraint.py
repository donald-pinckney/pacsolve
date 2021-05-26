from .version import Version

class Constraint(object):
  def __init__(self) -> None:
    super().__init__()

class ConstraintExactly(Constraint):
  def __init__(self, v: Version) -> None:
    super().__init__()
    self.v = v

class ConstraintGeq(Constraint):
  def __init__(self, v: Version) -> None:
    super().__init__()
    self.v = v

class ConstraintGt(Constraint):
  def __init__(self, v: Version) -> None:
    super().__init__()
    self.v = v

class ConstraintLeq(Constraint):
  def __init__(self, v: Version) -> None:
    super().__init__()
    self.v = v

class ConstraintLt(Constraint):
  def __init__(self, v: Version) -> None:
    super().__init__()
    self.v = v

class ConstraintCaret(Constraint):
  def __init__(self, v: Version) -> None:
    super().__init__()
    self.v = v

class ConstraintTilde(Constraint):
  def __init__(self, v: Version) -> None:
    super().__init__()
    self.v = v

class ConstraintAnd(Constraint):
  def __init__(self, left: Constraint, right: Constraint) -> None:
    super().__init__()
    self.left = left
    self.right = right

class ConstraintOr(Constraint):
  def __init__(self, left: Constraint, right: Constraint) -> None:
    super().__init__()
    self.left = left
    self.right = right
  
class ConstraintWildcardBug(Constraint):
  def __init__(self, major: int, minor: int) -> None:
    super().__init__()
    self.major = major
    self.minor = minor

class ConstraintWildcardMinor(Constraint):
  def __init__(self, major: int) -> None:
    super().__init__()
    self.major = major

class ConstraintWildcardMajor(Constraint):
  def __init__(self) -> None:
    super().__init__()

class ConstraintNot(Constraint):
  def __init__(self, c: Constraint) -> None:
    super().__init__()
    self.c = c