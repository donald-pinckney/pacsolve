from program_ast.constraint import *
from program_ast.dependency import *
from program_ast.program import *
from program_ast.version import *


def unwrap_singleton_dict(j):
  ks = j.keys()
  if len(ks) == 1:
    k = list(ks)[0]
    return k, j[k]
  else:
    raise ValueError()

def load_semver_version(j):
  return SemverVersion(**j)

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

def load_version_format(j):
  if j == "semver":
    return VersionFormat.SEMVER
  elif j == "string":
    return VersionFormat.STRING
  else:
    raise ValueError(j)

def load_program(j) -> Program:
  version_format = load_version_format(j['versionFormat'])
  if version_format == VersionFormat.SEMVER:
    version_format_fn = load_semver_version
  elif version_format == VersionFormat.STRING:
    version_format_fn = StringVersion
  else:
    raise ValueError(version_format)
  
  contexts = set(j['declaredContexts'])
  ops = [load_op(version_format_fn, oj) for oj in j['ops']]
  return Program(contexts, ops, version_format)