#!/usr/bin/env python3
# This script manages MinNPM experiments on Discovery, using Slurm.
#
import subprocess
import time
import argparse
import sys
import os
import pandas as pd
import cfut # Adrian Sampson's clusterfutures package.
from more_itertools import grouper

def main():
    parser = argparse.ArgumentParser(
        description='Manage MinNPM experiments on Discovery.')
    # Commands:
    # - run 
    # - gather
    parser.add_argument(
        'command', 
        choices=['run', 'gather', 'prepare'],
        help='Subcommand to run')
    args = parser.parse_args(sys.argv[1:2])
    if args.command == 'run':
        run(sys.argv[2:])
    elif args.command == 'gather':
        gather(sys.argv[2:])
    elif args.command == 'prepare':
        prepare(sys.argv[2:])

def projects_for_solver(base: str, solver: str):
    """
    The projects on which a particular solver ran.
    """
    p = os.path.join(base, solver)
    return {f for f in os.listdir(p) if os.path.isdir(os.path.join(p, f)) }

def gather(argv):
    parser = argparse.ArgumentParser(
        description='Gather results after running an experiment')
    parser.add_argument(
        'directory',
        help='Directory to gather results from')
    args = parser.parse_args(argv)
    directory = args.directory
    
    projects = projects_for_solver(directory, 'rosette').union(
        projects_for_solver(directory, 'vanilla'))

    df = pd.DataFrame(columns=['Project', 'Solver', 'Time'])
    for project in projects:
        solvers = ['rosette', 'vanilla']
        for solver in solvers:
            p = os.path.join(directory, solver, project, 'package', 'experiment.time')
            if not os.path.exists(p):
                continue
            with open(p) as f:
                time = float(f.read())
            df = df.append(
                {'Project': project, 'Solver': solver, 'Time': time},
                ignore_index=True)

    output_path = os.path.join(directory, 'results.csv') 
    df.to_csv(output_path)
    print(f'See {output_path}')

def prepare(argv):
    parser = argparse.ArgumentParser(description='Prepare NPM packages for benchmarking MinNPM')
    parser.add_argument(
        '--source',
        required=True,
        help='Directory with the downloaded packages')
    parser.add_argument(
        '--target',
        required=True,
        help='Directory to unpack the packages')
    parser.add_argument(
        '--tarballs_per_job',
        default=100,
        help='The number of tarballs to unpack in each job')
    args = parser.parse_args(argv)
    Prepare(args.source, args.target, args.tarballs_per_job).run()

class Prepare(object):

    def __init__(self, source, target, tarballs_per_job):
        self.source = source
        self.target = target
        self.tarballs_per_job = tarballs_per_job
        self.sbatch_lines = [
            "#SBATCH --time=00:05:00",
            "#SBATCH --partition=express",
            "#SBATCH --mem=1G"
        ]

    def run(self):
        if not os.path.isdir(self.source):
            raise Exception(f'{self.source} does not exist')
        if not os.path.isdir(self.target):
            raise Exception(f'{self.target} does not exist')

        tarballs_and_targets = remove_nones([
            self.tarball_and_target_dir(f) for f in os.listdir(self.source)])

        with cfut.SlurmExecutor(additional_setup_lines = self.sbatch_lines) as executor:
            jobs = grouper(tarballs_and_targets, self.tarballs_per_job)
            for err in executor.map(self.unpack_tarballs, jobs):
                if err is not None:
                    print(err)

    def target_dir(self, package_tgz):
        """
        Given a target directory and a package tarball, returns the target directory
        for the package.
        """
        return os.path.join(self.target, os.path.basename(package_tgz).replace('.tgz', ''))

    def tarball_and_target_dir(self, package_tgz):
        unpacked_package_dir = os.path.join(
            self.target,
            os.path.basename(package_tgz).replace('.tgz', ''))
        if os.path.isdir(unpacked_package_dir):
            return None
        return (os.path.join(self.source, package_tgz), unpacked_package_dir)

    def unpack_tarballs(self, tarballs_and_targets):
        results = [ ]
        for (tgz, target) in tarballs_and_targets:
            try:
                os.mkdir(target)
                if os.system(f'tar -C {target} -xzf {tgz}') != 0:
                    results.append(f'Error unpacking {tgz}')
            except:
                results.append(f'Error unpacking {tgz}')
        if len(results) > 0:
            return "\n".join(results)
        else:
            return None

def run(argv):
    parser = argparse.ArgumentParser(
        description='Benchmark MinNPM on a directory of NPM projects')
    parser.add_argument('--target', required=True,
      help='Directory with NPM projects')
    parser.add_argument('--timeout', type=int, default=600,
        help='Timeout for npm')
    args = parser.parse_args(argv)
    mode = os.path.basename(args.target)
    if mode == 'vanilla':
        Run(args.target, False, args.timeout).run()
    elif mode == 'rosette':
        Run(args.target, True, args.timeout).run()
    else:
        raise Exception('basename of target must be vanilla or rosette')


class Run(object):

    def __init__(self, target, rosette, timeout):
        self.target = target
        self.rosette = rosette
        self.timeout = timeout
        self.sbatch_lines = [
            "#SBATCH --time=00:12:00",
            "#SBATCH --partition=express",
            "#SBATCH --mem=8G",
            "#SBATCH --cpus-per-task=4",
            "module load discovery nodejs",
            "export PATH=$PATH:/work/arjunguha-research-group/software/bin",
            "eval `spack load --sh z3`"
        ]
        self.NPM_COMMAND = 'minnpm install --omit dev --omit peer --omit optional --ignore-scripts'.split(' ')
        self.MINNPM_COMMAND = 'minnpm install --rosette --ignore-scripts'.split(' ')

    def run(self):
        if not os.path.isdir(self.target):
            raise Exception(f'{self.target} directory does not exist')

        pkgs = self.list_pkg_paths()
        
        with cfut.SlurmExecutor(additional_setup_lines = self.sbatch_lines) as executor:
            for err in executor.map(self.run_minnpm, pkgs):
                if err is not None:
                    print(err)

    def list_pkg_paths(self):
        all_packages = [ os.path.join(self.target, p, "package") 
            for p in os.listdir(self.target) ]
        pending_packages = [ p 
            for p in all_packages 
            if not os.path.isfile(os.path.join(p, "experiment.time")) ]
        return pending_packages

    def run_minnpm(self, pkg_path):
        start_time = time.time()
        cmd = self.NPM_COMMAND if not self.rosette else self.MINNPM_COMMAND
        try:
            with open(f'{pkg_path}/experiment.out', 'wt') as out:
                exit_code = subprocess.Popen(cmd,
                    cwd=pkg_path,
                    stdout=out,
                    stderr=out).wait(self.timeout)
                duration = time.time() - start_time
                if exit_code != 0:
                    return f'Failed: {pkg_path}'
                with open(f'{pkg_path}/experiment.time', 'wt') as f:
                    f.write(f'{duration}')
                return None
        except subprocess.TimeoutExpired:
            return f'Timeout: {pkg_path}'


def remove_nones(seq):
    return [x for x in seq if x is not None]


if __name__ == '__main__':
    main()