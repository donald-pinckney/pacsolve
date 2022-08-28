import itertools
import json
import os
import subprocess
import sys
from typing import Any, Dict, List, Optional, Tuple
import pathlib
from tqdm import tqdm
import numpy as np
from tqdm.contrib.concurrent import process_map

DUMP_ERRORS = open('/dev/null', 'w')
memoized_cve_badness = dict()

def lookup_cve_badness(module_path: str, name: str, pack: Dict[str, Any]) -> float:
    if 'version' not in pack:
        print(f'Error (ignored): no version for {module_path}', file=sys.stderr)
        return 0, None

    version = pack['version']
    key = f'{name}:{version}'
    if key not in memoized_cve_badness:
        # print('miss', key)
        script_path = str(pathlib.Path(os.path.realpath(__file__)).parent.parent.joinpath('version-cve-badness', 'version-cve-badness.sh'))
        memoized_cve_badness[key] = float(subprocess.check_output([
                script_path, 
                name, 
                version],
                stderr=DUMP_ERRORS
            ).decode(
                'utf-8', 
                errors='ignore'
            ).strip())
    else:
        # print('hit', key)
        pass
    return memoized_cve_badness[key], key

class SolveResultEvaluation(object):
    def __init__(self, time, status, lock_path: str) -> None:
        self.time = time
        self.status = status
        self.lock_path = lock_path

        # NPM does not create the node_modules directory for packages with
        # zero dependencies. However, it also does not create node_modules for
        # packages that fail to install.
        lock_json: Optional[Dict[str, Any]] = None
        if os.path.isfile(lock_path):
            with open(lock_path, 'r') as f:
                lock_json = json.load(f)

        if lock_json is None:
            self.num_deps = 0
            self.cve_badness = 0
        else:
            self.num_deps = self.evaluate_num_deps(lock_json)
            self.cve_badness = self.evaluate_cve_badness(lock_json)

    @staticmethod
    def to_row_headers():
        return ['Time', 'NDeps', 'CVE', 'Status']
    
    def to_row_values(self):
        return [self.time, self.num_deps, self.cve_badness, self.status]

    def to_record_dict(self):
        return {'Time': self.time, 'NDeps': self.num_deps, 'CVE': self.cve_badness, 'Status': self.status}

    def all_packages(self, lock_json: Dict[str, Any]) -> List[Tuple[str, Dict[str, Any]]]:
        return [(p, pack) for (p, pack) in lock_json['packages'].items()]
    
    def non_link_packages(self, lock_json: Dict[str, Any]) -> List[Tuple[str, Dict[str, Any]]]:
        return [(p, pack) for (p, pack) in self.all_packages(lock_json) if not ('link' in pack and pack['link'])]

    def evaluate_num_deps(self, lock_json: Dict[str, Any]):
        return len(self.non_link_packages(lock_json))



    def evaluate_cve_badness(self, lock_json: Dict[str, Any]):
        cves_keys = list(process_map(cve_process_tuple, self.non_link_packages(lock_json), max_workers=24))
        cve_sum = sum(cve_val for (cve_val, k) in cves_keys)

        for cve_val, k in cves_keys:
            if cve_val > 0 and k is not None:
                print(f'CVE: {k} has a CVE badness of {cve_val}', file=sys.stderr)

        return cve_sum

        # return sum(cve_process_tuple(tup) for tup in tqdm(self.non_link_packages(lock_json), desc=" inner loop", position=1, leave=False))


def cve_process_tuple(tup):
    module_path, pack = tup
    name = strip_node_modules_from_name(module_path)
    return lookup_cve_badness(module_path, name, pack)

def strip_node_modules_from_name(module_path: str) -> str:
    parts = module_path.split('/')
    parts.reverse()
    parts = list(itertools.takewhile(lambda s: s != 'node_modules', parts))
    parts.reverse()
    return '/'.join(parts)

if __name__ == "__main__":
    import csv
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('solution_paths', nargs='*', default=None)
    args = parser.parse_args()
    lockfiles = args.solution_paths
    assert len(lockfiles) > 0

    for p in lockfiles:
        print(f'Evaluating solution at {p}', file=sys.stderr)
        res = SolveResultEvaluation(np.nan, 'success', p)
        writer = csv.writer(sys.stdout)
        writer.writerow(SolveResultEvaluation.to_row_headers())
        writer.writerow(res.to_row_values())

    
    
