#!/usr/bin/env python3
# This is a script to run a performance measurement. You must run it *after*
# main.py produces experiment.json files, since we strive to only run it on
# programs that were successfully run in parallel. This saves time.

import os
import sys
import argparse
import subprocess
import time
from util import read_json, eprint
from main import solve_command, MODE_CONFIGURATIONS

class Performance(object):

    def __init__(self, target, timeout, trials):
        self.target = target
        self.timeout = timeout
        self.trials = trials

        target_pieces = target.split('/')
        if target_pieces[-1] == 'vanilla':
            self.mode_configuration =  { 'rosette': False }
        elif target_pieces[-1] == 'rosette':
            self.mode_configuration =  {
                'rosette': True,
                'minimize': target_pieces[-2],
                'consistency': target_pieces[-3],
            }
        assert(self.mode_configuration in MODE_CONFIGURATIONS)

    def run_one(self, package_name: str, pkg_path: str):
        start_time = time.time()
        try:
            eprint(f'Timing {package_name} ...')
            output_path = f'{pkg_path}/experiment.out'
            with open(output_path, 'wt') as out:
                exit_code = subprocess.Popen(solve_command(self.mode_configuration),
                    cwd=pkg_path,
                    stdout=out,
                    stderr=out).wait(self.timeout)
            duration = time.time() - start_time
            if exit_code == 0:
                print(f'{package_name},{duration}',flush=True)
                return
            eprint(f'{package_name} failed with exit code {exit_code}')
        except subprocess.TimeoutExpired:
            eprint(f'{package_name} failed with timeout')
        except KeyboardInterrupt as e:
            eprint(f'{package_name} failed with keyboard interrupt')
            raise e
        except BaseException as e:
            eprint(f'{package_name} failed with exception {e}')

    def run(self):
        for package_name in os.listdir(self.target):
            package_path = os.path.join(self.target, package_name, 'package')
            if not os.path.isdir(package_path):
                eprint(f'Skipping {package_name} ({package_path} is not a directory)')
                continue
            parallel_experiment_path = os.path.join(package_path, 'experiment.json')
            if not os.path.isfile(parallel_experiment_path):
                eprint(f'Skipping {package_name} ({parallel_experiment_path} is not a file)')
                continue
            parallel_experiment_result = read_json(parallel_experiment_path)
            if parallel_experiment_result['status'] != 'success':
                eprint(f'Skipping {package_name} (parallel experiment failed)')
                continue
            for _ in range(0, self.trials):
                self.run_one(package_name, package_path)


def main():
    parser = argparse.ArgumentParser(
        description='Performance benchmarking, *after* parallel execution.')
    parser.add_argument('--target', required=True,
        help='Directory with all packages containing experiment.json files.')
    parser.add_argument('--timeout', type=int, default=600,
        help='Timeout for npm')
    parser.add_argument('--trials', type=int, default=2,
       help='Number of trials to run')
    args = parser.parse_args()
    Performance(args.target, args.timeout, args.trials).run()

if __name__ == '__main__':
    main()
