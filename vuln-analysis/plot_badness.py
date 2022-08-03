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
        assert False

def concrete_strict_upper(v: Tuple[int, int, None] | Tuple[int, None, None]) -> Tuple[int, int, int]:
    match v:
        case (x, None, None):
            return (x + 1, 0, 0)
        case (x, y, None):
            return (x, y + 1, 0)
        case _other:
            assert False

def concrete_lower(v: Tuple[int, int, None] | Tuple[int, None, None]) -> Tuple[int, int, int]:
    match v:
        case (x, None, None):
            return (x, 0, 0)
        case (x, y, None):
            return (x, y, 0)
        case _other:
            assert False

def parse_comp(comp_str: str) -> Tuple[Op, Tuple[int, int, int]]:
    op, v = comp_str.split(' ')
    v, v_concrete = parse_version(v)
    if op == '>':
        if v_concrete:
            return Op.GT, v  # type: ignore
        else:
            return Op.GTE, concrete_strict_upper(v)  # type: ignore
    elif op == '>=':
        if v_concrete:
            return Op.GTE, v  # type: ignore
        else:
            return Op.GTE, concrete_lower(v)  # type: ignore
    elif op == '<':
        if v_concrete:
            return Op.LT, v  # type: ignore
        else:
            return Op.LT, concrete_lower(v)  # type: ignore
    elif op == '<=':
        if v_concrete:
            return Op.LTE, v  # type: ignore
        else:
            return Op.LT, concrete_strict_upper(v)  # type: ignore
    else:
        assert False


class VersionRange(object):
    def __init__(self, range_str: str) -> None:
        self.comps = [parse_comp(comp_str.strip()) for comp_str in range_str.split(',')]
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
trans_badnesses = [sum(v.badness_of_point(p) for v in vulns) for p in trans_points]
trans_labels = [f"{p[0]}.{p[1]}.{p[2]}" for p in trans_points]
plt.scatter(x=np.arange(len(trans_points)), y=trans_badnesses)
plt.xticks(ticks=np.arange(len(trans_points)), labels=trans_labels)
plt.xlabel('Version')
plt.ylabel('CVE Badness Sum')
plt.title(f'{package_name} CVE Badness Plot')
plt.show()