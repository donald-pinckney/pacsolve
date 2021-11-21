#!/usr/bin/env python3
# This script manages MinNPM experiments on Discovery, using Slurm.
#
import subprocess
import time
import argparse
import sys
import os
import glob
import json
import numpy as np
import pandas as pd
import concurrent.futures
import cfut # Adrian Sampson's clusterfutures package.
from more_itertools import grouper, chunked
import itertools

def main():
    parser = argparse.ArgumentParser(
        description='Manage MinNPM experiments on Discovery.')
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

def gather(argv):
    parser = argparse.ArgumentParser(
        description='Gather results after running an experiment')
    parser.add_argument(
        'directory',
        help='Directory to gather results from')
    args = parser.parse_args(argv)
    Gather(args.directory).gather()

class Gather(object):

    def __init__(self, directory):
        self.directory = os.path.normpath(directory)
        self.solvers = [
            'vanilla'
        ] + [
            os.sep.join(os.path.normpath(p).split(os.sep)[-3:]) 
            for p in glob.glob(f'{self.directory}/rosette/*/*/')
        ]
        print(f'Gathering results for the solvers: {self.solvers}')

    def projects_for_solver(self, solver: str):
        """
        The projects on which a particular solver ran.
        """
        p = os.path.join(self.directory, solver)
        return {f for f in os.listdir(p) if os.path.isdir(os.path.join(p, f)) }

    def num_deps(self, solver, project):
        """
        Calculates the number of dependencies. This function assumes that
        'npm install' was sucessful. It is critical that the check is performed
        correctly: if not, it will false report zero dependencies.
        """
        p = os.path.join(
            self.directory,
            solver,
            project,
            'package',
            'node_modules',
            '.package-lock.json')
        # NPM does not create the node_modules directory for packages with
        # zero dependencies. However, it also does not create node_modules for
        # packages that fail to install.
        if not os.path.isfile(p):
            return 0
        with open(p, 'r') as f:
            data = json.load(f)
            n = 0
            for _, v in data['packages'].items():
                if 'link' in v and v['link']:
                    continue
                n += 1
            return n

    def project_times(self, project: str):
        """
        Times with both solves for the project.
        """
        df = pd.DataFrame(columns=['Project', 'Solver', 'Time', 'NDeps'])
        for solver in self.solvers:
            p = os.path.join(self.directory, solver, project, 'package', 'experiment.json')
            if not os.path.exists(p):
                continue
            p_result = read_json(p)
            if p_result['status'] != 'success':
                continue
            df = df.append(
                {
                    'Project': project, 
                    'Solver': solver,
                    'Time': p_result['time'],
                    'NDeps': self.num_deps(solver, project)
                },
                ignore_index=True)
        return df

    def gather(self):
        projects = {prj for solver in self.solvers for prj in self.projects_for_solver(solver)}

        df = pd.DataFrame(columns=['Project', 'Solver', 'Time', 'NDeps'])
        # Process pool is faster than thread pool. This is a way of fudging
        # nonblocking I/O. Why 100 workers? Why not?
        with concurrent.futures.ProcessPoolExecutor(max_workers=100) as executor:
            for df_project in executor.map(self.project_times, projects):
                df = df.append(df_project)

        output_path = os.path.join(self.directory, 'results.csv') 
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

#        results = self.unpack_tarballs(tarballs_and_targets)
#        if results is not None:
#            print(results)

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
                if subprocess.call(['tar', '-C', target, '-xzf', tgz], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) != 0:
                    results.append(f'Error unpacking {tgz}')
            except Exception as err:
                results.append(f'Error unpacking {tgz}: {err}')
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
    parser.add_argument('--cpus-per-task', type=int, default=24,
       help='Number of CPUs to request on each node')
    args = parser.parse_args(argv)

    target = os.path.normpath(args.target)
    target_components = target.split(os.sep)

    if 'vanilla' in target_components:
        mode_configuration = {
            'rosette': False
        }
    elif 'rosette' in target_components and target_components[-3] == 'rosette':
        mode_configuration = {
            'rosette': True,
            'minimize': target_components[-1],
            'consistency': target_components[-2]
        }
    else:
        raise Exception('target must be of the form: <stuff>/vanilla OR <stuff>/rosette/<consistency>/<min>')

    Run(target, mode_configuration, args.timeout, args.cpus_per_task).run()

class Run(object):

    def __init__(self, target, mode_configuration, timeout, cpus_per_task):
        self.target = target
        self.mode_configuration = mode_configuration
        self.timeout = timeout
        self.cpus_per_task = cpus_per_task
        print(cpus_per_task)
        self.sbatch_lines = [
            "#SBATCH --time=00:12:00",
            "#SBATCH --partition=express",
            "#SBATCH --mem=8G",
            f'#SBATCH --cpus-per-task={cpus_per_task}',
            "module load discovery nodejs",
            "export PATH=$PATH:/work/arjunguha-research-group/software/bin",
            "eval `spack load --sh z3`"
        ]

        if mode_configuration['rosette']:
            self.SOLVE_COMMAND = [
                'minnpm', 'install', '--rosette', '--ignore-scripts', 
                '--consistency', mode_configuration['consistency'], 
                '--minimize', mode_configuration['minimize']
            ]
        else:
            self.SOLVE_COMMAND = 'minnpm install --omit dev --omit peer --omit optional --ignore-scripts'.split(' ')

    def run_chunk(self, pkgs):
        print(f'Will handle {len(pkgs)}')
        # Tip: Cannot use ProcessPoolExecutor with the ClusterFutures executor. It seems like
        # ProcessPoolExector forks the process with the same command-line arguments, including
        # loading ClusterFutures's remote library, and that makes things go awry.
        errs = [ ]
        with concurrent.futures.ThreadPoolExecutor(max_workers=self.cpus_per_task) as executor:
            for err in suppressed_iterator(executor.map(self.run_minnpm, pkgs)):
                if err is not None:
                    errs.append(err)
        if len(errs) == 0:
            return None
        return '\n'.join(errs)
    
    def run(self):
        if not os.path.isdir(self.target):
            raise Exception(f'{self.target} directory does not exist')

        print(f'Listing packages.')
        pkgs = self.list_pkg_paths()
        print(f'Will run on {len(pkgs)} packages.')
        pkg_chunks = chunked(pkgs, self.cpus_per_task)
        # print(len(list(pkg_chunks)))

        with cfut.SlurmExecutor(additional_setup_lines = self.sbatch_lines, keep_logs=True) as executor:
            for err in suppressed_iterator(executor.map(self.run_chunk, pkg_chunks)):
                if err is not None:
                    print(err)

    def list_pkg_paths(self):
        all_packages = [ os.path.join(self.target, p, "package") 
            for p in os.listdir(self.target) ]
        pending_packages = [ p 
            for p in all_packages 
            if not os.path.isfile(os.path.join(p, "experiment.json")) ]
        return pending_packages

    def get_npmstatus(self, path):
        with open(path, 'r') as out:
            lines = [ line.strip() for line in out.readlines() ]
        # The error code is usually on the first line. But, the MinNPM solver
        # prints stuff that appears before it.
        err_code = [ line for line in lines if line.startswith('npm ERR! code') ]
        if len(err_code) != 1:
            return None
        pieces = err_code.split(' ')
        if len(pieces) != 4:
            return None
        return pieces[3]

    def run_minnpm(self, pkg_path):
        start_time = time.time()
        try:
            output_path = f'{pkg_path}/experiment.out'
            with open(output_path, 'wt') as out:
                exit_code = subprocess.Popen(self.SOLVE_COMMAND,
                    cwd=pkg_path,
                    stdout=out,
                    stderr=out).wait(self.timeout)
            duration = time.time() - start_time
            output_status_path = f'{pkg_path}/experiment.json'
            if exit_code == 0:
                write_json(output_status_path,
                    { 'status': 'success', 'time': duration })
                return None
            status = self.get_npmstatus(output_path)
            if status in [ 'ERESOLVE', 'ETARGET', 'EUNSUPPORTEDPROTOCOL', 'EBADPLATFORM' ]:
                write_json(output_status_path, { 'status': 'cannot_install', 'reason': status })
                return None
            return f'Failed: {pkg_path}'
        except subprocess.TimeoutExpired:
            return f'Timeout: {pkg_path}'


def remove_nones(seq):
    return [x for x in seq if x is not None]

class suppressed_iterator:
    def __init__(self, wrapped_iter, skipped_exc = Exception):
        self.wrapped_iter = wrapped_iter
        self.skipped_exc  = skipped_exc

    def __iter__(self):
        return self

    def __next__(self):
        while True:
            try:
                return next(self.wrapped_iter)
            except StopIteration:
                raise
            except self.skipped_exc as exn:
                print(f'Skipped exception {exn}')
                pass

def write_json(path, data):
    with open(path, 'wt') as out:
        out.write(json.dumps(data))

def read_json(path: str) -> any:
    with open(path, 'r') as f_in:
        return json.load(f_in)

if __name__ == '__main__':
    start = time.time()
    main()
    end = time.time()
    duration = int(end - start)
    print(f'Time taken: {duration} seconds')
