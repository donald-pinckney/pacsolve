from abc import ABC, abstractmethod
from enum import Enum, auto

# Base class for different supported Version formats
class Version(ABC):
  def __init__(self) -> None:
    super().__init__()

  @abstractmethod
  def to_json(self):
    pass
  

# We have either a semver format
class SemverVersion(Version):
  def __init__(self, major: int, minor: int, bug: int) -> None:
    super().__init__()
    self.major = major
    self.minor = minor
    self.bug = bug

  def __members(self):
    return (self.major, self.minor, self.bug)

  def __eq__(self, other):
    if type(other) is type(self):
      return self.__members() == other.__members()
    else:
      return False

  def __hash__(self):
    return hash(self.__members())

  def to_json(self):
    return {'major': self.major, 'minor': self.minor, 'bug': self.bug}

# Or a version that is just a string blob
class StringVersion(Version):
  def __init__(self, version_string: str) -> None:
    super().__init__()
    self.version_string = version_string

  def __members(self):
    return self.version_string

  def __eq__(self, other):
    if type(other) is type(self):
      return self.__members() == other.__members()
    else:
      return False

  def __hash__(self):
    return hash(self.__members())

  def to_json(self):
    return self.version_string

# We also have an explicit enum for the chosen version format.
class VersionFormat(Enum):
  SEMVER = auto()
  STRING = auto()

  def to_json(self):
    if self is VersionFormat.SEMVER:
      return "semver"
    elif self is VersionFormat.STRING:
      return "string"
    else:
      raise ValueError()
