import itertools
import json
import os
import subprocess
import sys
from typing import Any, Dict, List, Optional, Tuple
import pathlib

DUMP_ERRORS = open('/dev/null', 'w')
memoized_cve_badness = dict()

def lookup_cve_badness(module_path: str, name: str, pack: Dict[str, Any], package_lock_path: str) -> float:
    if 'version' not in pack:
        print(f'Error (ignored): no version for {module_path} in {package_lock_path}', file=sys.stderr)
        return 0

    version = pack['version']
    key = f'{name}:{version}'
    if key not in memoized_cve_badness:
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
    return memoized_cve_badness[key]

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

    def all_packages(self, lock_json: Dict[str, Any]) -> List[Tuple[str, Dict[str, Any]]]:
        return [(p, pack) for (p, pack) in lock_json['packages'].items()]
    
    def non_link_packages(self, lock_json: Dict[str, Any]) -> List[Tuple[str, Dict[str, Any]]]:
        return [(p, pack) for (p, pack) in self.all_packages(lock_json) if not ('link' in pack and pack['link'])]

    def evaluate_num_deps(self, lock_json: Dict[str, Any]):
        return len(self.non_link_packages(lock_json))

    def strip_node_modules_from_name(self, module_path: str) -> str:
        parts = module_path.split('/')
        parts.reverse()
        parts = list(itertools.takewhile(lambda s: s != 'node_modules', parts))
        parts.reverse()
        return '/'.join(parts)

    def evaluate_cve_badness(self, lock_json: Dict[str, Any]):
        return sum(lookup_cve_badness(module_path, self.strip_node_modules_from_name(module_path), pack, self.lock_path) for (module_path, pack) in self.non_link_packages(lock_json))


if __name__ == "__main__":
    import csv
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('solution_path', nargs='?', default=None)
    args = parser.parse_args()

    solution_path: Optional[str] = args.solution_path
    if solution_path is None:
        lockpath = pathlib.Path(os.path.join('node_modules', '.package-lock.json')).resolve()
    elif solution_path.endswith('node_modules/.package-lock.json'):
        lockpath = pathlib.Path(solution_path).resolve()
    elif solution_path.endswith('package-lock.json'):
        lockpath = pathlib.Path(solution_path).parent.joinpath('node_modules', '.package-lock.json').resolve()
    elif solution_path.endswith('package.json'):
        lockpath = pathlib.Path(solution_path).parent.joinpath('node_modules', '.package-lock.json').resolve()
    else:
        p = pathlib.Path(solution_path)
        assert p.is_dir()
        lockpath = p.joinpath('node_modules', '.package-lock.json').resolve()
    
    print(f'Evaluating solution at {lockpath}', file=sys.stderr)

    if not lockpath.exists():
        print(f'WARNING: {lockpath} does not exist', file=sys.stderr)
        res = SolveResultEvaluation('n/a', 'failure or no deps', str(lockpath))
    else:
        res = SolveResultEvaluation('n/a', 'success', str(lockpath))
    
    writer = csv.writer(sys.stdout)
    writer.writerow(SolveResultEvaluation.to_row_headers())
    writer.writerow(res.to_row_values())
