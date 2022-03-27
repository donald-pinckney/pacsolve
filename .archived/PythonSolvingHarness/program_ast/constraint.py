from .version import Version

class Constraint(object):
  def __init__(self) -> None:
    super().__init__()

  def to_json(self):
    pass

class ConstraintExactly(Constraint):
  def __init__(self, v: Version) -> None:
    super().__init__()
    self.v = v

  def to_json(self):
    return {"exactly": self.v.to_json()}

class ConstraintGeq(Constraint):
  def __init__(self, v: Version) -> None:
    super().__init__()
    self.v = v

  def to_json(self):
    return {"geq": self.v.to_json()}

class ConstraintGt(Constraint):
  def __init__(self, v: Version) -> None:
    super().__init__()
    self.v = v

  def to_json(self):
    return {"gt": self.v.to_json()}

class ConstraintLeq(Constraint):
  def __init__(self, v: Version) -> None:
    super().__init__()
    self.v = v

  def to_json(self):
    return {"leq": self.v.to_json()}

class ConstraintLt(Constraint):
  def __init__(self, v: Version) -> None:
    super().__init__()
    self.v = v

  def to_json(self):
    return {"lt": self.v.to_json()}

class ConstraintCaret(Constraint):
  def __init__(self, v: Version) -> None:
    super().__init__()
    self.v = v

  def to_json(self):
    return {"caret": self.v.to_json()}

class ConstraintTilde(Constraint):
  def __init__(self, v: Version) -> None:
    super().__init__()
    self.v = v

  def to_json(self):
    return {"tilde": self.v.to_json()}

class ConstraintAnd(Constraint):
  def __init__(self, left: Constraint, right: Constraint) -> None:
    super().__init__()
    self.left = left
    self.right = right

  def to_json(self):
    return {"and": {"left": self.left.to_json(), "right": self.right.to_json()}}

class ConstraintOr(Constraint):
  def __init__(self, left: Constraint, right: Constraint) -> None:
    super().__init__()
    self.left = left
    self.right = right

  def to_json(self):
    return {"or": {"left": self.left.to_json(), "right": self.right.to_json()}}

  
class ConstraintWildcardBug(Constraint):
  def __init__(self, major: int, minor: int) -> None:
    super().__init__()
    self.major = major
    self.minor = minor

  def to_json(self):
    return {"wildcardBug": {"major": self.major, "minor": self.minor}}


class ConstraintWildcardMinor(Constraint):
  def __init__(self, major: int) -> None:
    super().__init__()
    self.major = major
  
  def to_json(self):
    return {"wildcardMinor": {"major": self.major}}


class ConstraintWildcardMajor(Constraint):
  def __init__(self) -> None:
    super().__init__()

  def to_json(self):
    return {"wildcardMajor": None}

class ConstraintNot(Constraint):
  def __init__(self, c: Constraint) -> None:
    super().__init__()
    self.c = c
  
  def to_json(self):
    return {"not": self.c.to_json()}