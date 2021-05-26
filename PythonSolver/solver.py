import json
import argparse
from enum import Enum, auto
from typing import List, Set

class Version(object):
  def __init__(self) -> None:
    super().__init__()

class StringVersion(Version):
  def __init__(self, version_string: str) -> None:
    super().__init__()
    self.version_string = version_string

class SemverVersion(object):
  def __init__(self, major: int, minor: int, bug: int) -> None:
    super().__init__()
    self.major = major
    self.minor = minor
    self.bug = bug

def load_semver_version(j):
  return SemverVersion(**j)

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


class Dependency(object):
  def __init__(self, package_to_depend_on: str, constraint: Constraint) -> None:
    super().__init__()
    self.package_to_depend_on = package_to_depend_on
    self.constraint = constraint

class Op(object):
  def __init__(self) -> None:
    super().__init__()

class OpPublish(Op):
  def __init__(self, package: str, version: Version, dependencies: List[Dependency]) -> None:
    super().__init__()
    self.package = package
    self.version = version
    self.dependencies = dependencies

class OpYank(Op):
  def __init__(self, package: str, version: Version) -> None:
    super().__init__()
    self.package = package
    self.version = version

class OpSolve(Op):
  def __init__(self, in_context: str, dependencies: List[Dependency]) -> None:
    super().__init__()
    self.in_context = in_context
    self.dependencies = dependencies

def unwrap_singleton_dict(j):
  ks = j.keys()
  if len(ks) == 1:
    k = list(ks)[0]
    return k, j[k]
  else:
    raise ValueError()

def load_constraint(v_fn, j) -> Constraint:
  k, j = unwrap_singleton_dict(j)
  if k == 'exactly':
    return ConstraintExactly(v_fn(j))
  elif k == 'geq':
    return ConstraintGeq(v_fn(j))
  elif k == 'gt':
    return ConstraintGt(v_fn(j))
  elif k == 'leq':
    return ConstraintLeq(v_fn(j))
  elif k == 'lt':
    return ConstraintLt(v_fn(j))
  elif k == 'caret':
    return ConstraintCaret(v_fn(j))
  elif k == 'tilde':
    return ConstraintTilde(v_fn(j))
  elif k == 'and':
    return ConstraintAnd(load_constraint(v_fn, j['left']), load_constraint(v_fn, j['right']))
  elif k == 'or':
    return ConstraintOr(load_constraint(v_fn, j['left']), load_constraint(v_fn, j['right']))
  elif k == 'wildcardBug':
    return ConstraintWildcardBug(j['major'], j['minor'])
  elif k == 'wildcardMinor':
    return ConstraintWildcardMinor(j['major'])
  elif k == 'wildcardMajor':
    return ConstraintWildcardMajor()
  elif k == 'not':
    return ConstraintNot(load_constraint(v_fn, j))
  else:
    raise ValueError(k)
    
     
    

def load_dependency(v_fn, j) -> Dependency:
  return Dependency(j['packageToDependOn'], load_constraint(v_fn, j['constraint']))

def load_op_publish(v_fn, j) -> OpPublish:
  deps = [load_dependency(v_fn, dj) for dj in j['dependencies']]
  return OpPublish(j['package'], v_fn(j['version']), deps)

def load_op_yank(v_fn, j) -> OpYank:
  return OpYank(j['package'], v_fn(j['version']))

def load_op_solve(v_fn, j) -> OpSolve:
  deps = [load_dependency(v_fn, dj) for dj in j['dependencies']]
  return OpSolve(j['context'], deps)


def load_op(v_fn, j) -> Op:
  k, j = unwrap_singleton_dict(j)
  if k == 'op_publish':
    return load_op_publish(v_fn, j)
  elif k == 'op_yank':
    return load_op_yank(v_fn, j)
  elif k == 'op_solve':
    return load_op_solve(v_fn, j)
  else:
    raise ValueError()

class VersionFormat(Enum):
  SEMVER = auto()

def load_version_format(j):
  if j == "semver":
    return VersionFormat.SEMVER
  else:
    raise ValueError(j)

class Program(object):
  def __init__(self, version_format: VersionFormat, contexts: Set[str], ops: List[Op]) -> None:
    super().__init__()
    self.contexts = contexts
    self.ops = ops

def load_program(j) -> Program:
  print()
  print(j)

  version_format = j['versionFormat']
  if version_format == 'semver':
    version_format_fn = load_semver_version
  elif version_format == 'string':
    version_format_fn = StringVersion
  else:
    raise ValueError(version_format)
  
  contexts = set(j['declaredContexts'])
  ops = [load_op(version_format_fn, oj) for oj in j['ops']]
  return Program(version_format, contexts, ops)

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('--in-json', required=True)
  parser.add_argument('--out-json', required=True)
  args = parser.parse_args()
  in_path = args.in_json
  out_path = args.out_json

  with open(in_path, 'r') as in_f:
    in_data = json.load(in_f)

  prog = load_program(in_data)

  print()
  print(repr(prog))

  result = prog.run()
  
  result_json = result.to_json()

  with open(out_path, 'w') as out_f:
    json.dump(result_json, out_f)


if __name__ == "__main__":
  main()