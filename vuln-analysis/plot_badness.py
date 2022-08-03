from typing import List, Optional, Tuple
import numpy as np
import requests
import pandas as pd
import matplotlib.pyplot as plt
import sys

from enum import Enum, auto
class Op(Enum):
    GT = auto()
    GTE = auto()
    LT = auto()
    LTE = auto()

    def test(self, lhs: Tuple[int, int, int], rhs: Tuple[int, int, int]) -> bool:
        if self == Op.GT:
            return lhs > rhs
        elif self == Op.GTE:
            return lhs >= rhs
        elif self == Op.LT:
            return lhs < rhs
        elif self == Op.LTE:
            return lhs <= rhs
        else:
            assert False

def parse_version(v_str: str):
    if '-' in v_str:
        return None

    version_parts = v_str.split('.')
    if len(version_parts) == 3:
        x, y, z = version_parts
        return (int(x), int(y), int(z)), True
    elif len(version_parts) == 2:
        x, y = version_parts
        return (int(x), int(y), None), False
    elif len(version_parts) == 1:
        x, = version_parts
        return (int(x), None, None), False
    else:
        return None

def parse_version_concrete(v_str: str) -> Optional[Tuple[int, int, int]]:
    x = parse_version(v_str)
    if x is not None:
        assert x[1] == True
        return x[0]
    else:
        return None

def parse_version_unwrap(v_str: str):
    x = parse_version(v_str)
    if x is not None:
        return x
    else:
        print(v_str)
        assert False

def concrete_strict_upper(v: Tuple[int, int, None] | Tuple[int, None, None] | Tuple[int, int, int]) -> Tuple[int, int, int]:
    match v:
        case (x, None, None):
            return (x + 1, 0, 0)
        case (x, y, None):
            return (x, y + 1, 0)
        case (x, y, z):
            return (x, y, z + 1)

def concrete_lower(v: Tuple[int, int, None] | Tuple[int, None, None]) -> Tuple[int, int, int]:
    match v:
        case (x, None, None):
            return (x, 0, 0)
        case (x, y, None):
            return (x, y, 0)
        case _other:
            assert False

def parse_comp(comp_str: str) -> List[Tuple[Op, Tuple[int, int, int]]]:
    op, v = comp_str.split(' ')
    v, v_concrete = parse_version_unwrap(v)
    if op == '>':
        if v_concrete:
            return [(Op.GT, v)]  # type: ignore
        else:
            return [(Op.GTE, concrete_strict_upper(v))]  # type: ignore
    elif op == '>=':
        if v_concrete:
            return [(Op.GTE, v)]  # type: ignore
        else:
            return [(Op.GTE, concrete_lower(v))]  # type: ignore
    elif op == '<':
        if v_concrete:
            return [(Op.LT, v)]  # type: ignore
        else:
            return [(Op.LT, concrete_lower(v))]  # type: ignore
    elif op == '<=':
        if v_concrete:
            return [(Op.LTE, v)]  # type: ignore
        else:
            return [(Op.LT, concrete_strict_upper(v))]  # type: ignore
    elif op == '=':
        if v_concrete:
            return [(Op.GTE, v), (Op.LT, concrete_strict_upper(v))]  # type: ignore
        else:
            return [(Op.GTE, concrete_lower(v)), (Op.LT, concrete_strict_upper(v))]  # type: ignore
    else:
        print(op)
        assert False


class VersionRange(object):
    def __init__(self, range_str: str) -> None:
        self.comps = [c for comp_str in range_str.split(',') for c in parse_comp(comp_str.strip())]
        assert len(self.comps) in [1, 2]

    def transition_points(self) -> List[Tuple[int, int, int]]:
        return [v for (_, v) in self.comps]

    def includes(self, other_v: Tuple[int, int, int]) -> bool:
        return all(op.test(other_v, v) for (op, v) in self.comps)        
        

class Vuln(object):
    def __init__(self, j) -> None:
        self.badness: float = j['badness']
        self.range = VersionRange(j['range'])

    def badness_of_point(self, v: Tuple[int, int, int]) -> float:
        if self.range.includes(v):
            return self.badness
        else:
            return 0

package_name = sys.argv[1]
vulns_raw = requests.get(f'https://advisory.federico.codes/api/cached/npm/{package_name}').json()
vulns = [Vuln(vj) for vj in vulns_raw]
trans_points = list(set(p for v in vulns for p in v.range.transition_points()))
trans_points.sort()

reg_versions = [parse_version_concrete(v) for v in requests.get(f'https://registry.npmjs.org/{package_name}').json()['versions'].keys()]
reg_versions = [v for v in reg_versions if v is not None]

all_versions = sorted(list(set(trans_points + reg_versions)))
all_badnesses = np.array([sum(v.badness_of_point(p) for v in vulns) for p in all_versions])
max_bad = np.max(all_badnesses)

trans_indices = np.array([all_versions.index(p) for p in trans_points], dtype=np.int32)
plt.scatter(x=np.arange(len(all_versions)), y=all_badnesses)
plt.scatter(x=trans_indices, y=all_badnesses[trans_indices])

for i in trans_indices:
    p = all_versions[i]
    plt.annotate(f"{p[0]}.{p[1]}.{p[2]}", (i, all_badnesses[i] + max_bad / 40))

trans_labels = [f"{p[0]}.{p[1]}.{p[2]}" for p in trans_points]
plt.xticks(ticks=trans_indices, labels=trans_labels)

plt.xlabel('Version')
plt.ylabel('CVE Badness Sum')
plt.title(f'{package_name} CVE Badness Plot')
plt.show()