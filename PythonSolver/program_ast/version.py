from enum import Enum, auto

# Base class for different supported Version formats
class Version(object):
  def __init__(self) -> None:
    super().__init__()

# We have either a semver format
class SemverVersion(object):
  def __init__(self, major: int, minor: int, bug: int) -> None:
    super().__init__()
    self.major = major
    self.minor = minor
    self.bug = bug

# Or a version that is just a string blob
class StringVersion(Version):
  def __init__(self, version_string: str) -> None:
    super().__init__()
    self.version_string = version_string

# We also have an explicit enum for the chosen version format.
class VersionFormat(Enum):
  SEMVER = auto()
  STRING = auto()
