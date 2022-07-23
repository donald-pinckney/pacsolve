from os import listdir
from os.path import isfile, join
import contextlib
import os
import tempfile
import subprocess
import json
import shutil
import errno
import time
import pandas as pd
from io import StringIO
import sys

import tarball_helpers

GLOBAL_TESTING_PREFIX = "/mnt/data/donald/npm_global_testing_prefix"
TARBALL_ROOT = sys.argv[1].rstrip("/")
USE_MINNPM = True


def subproccess_get_result(command, name, timeout):
    start = time.time()
    try:
        completed = subprocess.run(command, capture_output=True, stdin=subprocess.DEVNULL, timeout=timeout)
    except subprocess.TimeoutExpired:
        dt = time.time() - start
        return {f'{name}_status': None, f'{name}_stdout': None, f'{name}_stderr': None, f'{name}_time': dt, f'{name}_timeout': True}
    dt = time.time() - start
    return {f'{name}_status': completed.returncode, f'{name}_stdout': completed.stdout.decode('utf-8', 'backslashreplace'), f'{name}_stderr': completed.stderr.decode('utf-8', 'backslashreplace'), f'{name}_time': dt, f'{name}_timeout': False}

def combine_install_results(install_results1, install_results2):
    for key in install_results2:
        if key in install_results1:
            if key.endswith("_status"):
                assert install_results1[key] is not None
                assert install_results1[key] == 0
                install_results1[key] = install_results2[key]
            elif key.endswith("_stdout") or key.endswith("_stderr"):
                install_results1[key] = install_results1[key] + install_results2[key]
            elif key.endswith("_time"):
                install_results1[key] = install_results1[key] + install_results2[key]
            elif key.endswith("_timeout"):
                assert install_results1[key] == False
                install_results1[key] = install_results2[key]
            else:
                assert False
        else:
            install_results1[key] = install_results2[key]
    return install_results1

def install_dev_dependencies(j, tarball_name, pbar):
    result = dict()
    devDeps = j["devDependencies"] if "devDependencies" in j else {}
    optionalDeps = j["optionalDependencies"] if "optionalDependencies" in j else {}
    peerDeps = j["peerDependencies"] if "peerDependencies" in j else {}

    thingsToInstall = {**optionalDeps, **peerDeps, **devDeps}
    if "npm" in thingsToInstall:
        print("NO NO NO, WE CAN'T DEAL WITH INSTALLING ANOTHER NPM")
        assert False
    
    # 1. Nuke GLOBAL_TESTING_PREFIX
    shutil.rmtree(GLOBAL_TESTING_PREFIX, ignore_errors=True)
    os.mkdir(GLOBAL_TESTING_PREFIX)

    # 2. Copy .npmrc file, if exists
    if os.path.exists('.npmrc'):
        shutil.copy('.npmrc', join(GLOBAL_TESTING_PREFIX, '.npmrc'))

    with tarball_helpers.pushd(GLOBAL_TESTING_PREFIX):
        # 3. Copy package.json, but removing all normal dependencies
        j["dependencies"] = {}
        tarball_helpers.write_json('package.json', j)

        # 4. Do the install
        pbar.set_description(f"{tarball_name} (install dev vanilla)".rjust(50))
        result = subproccess_get_result(['npm', 'install', '--ignore-scripts', '--package-lock'], 'install', timeout=60*10)
    
    if result['install_status'] != 0:
        return result
    
    pbar.set_description(f"{tarball_name} (install merge)".rjust(50))
    return combine_install_results(result, merge_install(GLOBAL_TESTING_PREFIX))


def delete_existing_solution():
    shutil.rmtree("node_modules", ignore_errors=True)
    if os.path.exists('package-lock.json'):
        os.remove('package-lock.json')

def merge_install(from_dir):
    # 0. Merge package-lock.json and node_modules/.package-lock.json
    # Not sure if this is needed, skipping for now

    from_node_modules = join(from_dir, 'node_modules')
    from_node_modules_bin = join(from_dir, 'node_modules', '.bin')
    to_node_modules = 'node_modules'
    to_node_modules_bin = join('node_modules', '.bin')

    warnings = ""

    assert os.path.isabs(from_node_modules)
    assert os.path.isabs(from_node_modules_bin)

    # 1. For each directory d other than .bin/ inside join(from_dir, 'node_modules/'):
    # if d does not exist in 'node_modules/', copy d in, and use cp -a
    with os.scandir(from_node_modules) as from_modules_it:
        for from_module in from_modules_it:
            assert not from_module.is_symlink()
            if from_module.is_file():
                assert from_module.name == ".package-lock.json"
            
            if from_module.is_dir() and from_module.name != ".bin":
                to_module = join(to_node_modules, from_module.name)
                if os.path.exists(to_module):
                    warnings += f"\nWARNING: CONFLICT WHEN MERGING {from_dir} to cwd. Module {from_module.name} exists in both places. Preferring to keep cwd version.\n"
                else:
                    shutil.copytree(from_module.path, to_module, symlinks=True)

    
    # 2. If 'node_modules/.bin/' doesn't exist, create it
    if not os.path.exists(to_node_modules_bin):
        os.mkdir(to_node_modules_bin)

    # 3. For each symlink f inside join(from_dir, 'node_modules', '.bin/'):
    # if f does not exist in 'node_modules/.bin/', copy f in. Use cp -P to copy it.
    with os.scandir(from_node_modules_bin) as from_bin_it:
        for from_bin in from_bin_it:
            assert from_bin.is_symlink()

            to_bin = join(to_node_modules_bin, from_bin.name)
            if os.path.exists(to_bin):
                warnings += f"\nWARNING: CONFLICT WHEN MERGING {from_dir} to cwd. Binary link {from_bin.name} exists in both places. Preferring to keep cwd version.\n"
            else:
                # print(f"copy {from_bin.path} to {to_bin}, cwd = {os.getcwd()}", file=sys.stderr)
                shutil.copy(from_bin.path, to_bin, follow_symlinks=False)
    
    return {'install_status': 0, 'install_stdout': warnings, 'install_stderr': '', 'install_time': 0, 'install_timeout': False}


def test_tarball(tarball_name, pbar):
    shutil.rmtree(GLOBAL_TESTING_PREFIX, ignore_errors=True)

    pbar.set_description(f"{tarball_name} (init)".rjust(50))

    result = {'name': tarball_name, 'root': TARBALL_ROOT}
    with tarball_helpers.unzip_and_pushd(TARBALL_ROOT, tarball_name):
        j = tarball_helpers.load_json('package.json')
        if "scripts" not in j:
            result['has_build_script'] = False
            result['has_test_script'] = False
        else:
            scripts = j["scripts"]
            result['has_build_script'] = "build" in scripts
            result['has_test_script'] = "test" in scripts

        result['did_run_install'] = False
        result['did_run_build'] = False
        result['did_run_test'] = False
        result['skipped_esm'] = False

        if USE_MINNPM:
            result['solve_type'] = 'minnpm'
        else:
            result['solve_type'] = 'vanilla'

        # Check if ESM and MinNPM: can't handle this case
        # if USE_MINNPM and "type" in j and j["type"] == "module":
        #     result['skipped_esm'] = True
        #     return result
        
        # Clear old possible results
        delete_existing_solution()

        result['did_run_install'] = True
        if USE_MINNPM:
            pbar.set_description(f"{tarball_name} (install minnpm)".rjust(50))
            result = {**result, **subproccess_get_result(['npm', 'install', '--minnpm', '--ignore-scripts', '--package-lock'], 'install', timeout=60*10)}
            if result['install_status'] != 0:
                return result
            
            result = combine_install_results(result, install_dev_dependencies(j, tarball_name, pbar))
            if result['install_status'] != 0:
                return result
        else:
            pbar.set_description(f"{tarball_name} (install vanilla)".rjust(50))
            result = {**result, **subproccess_get_result(['npm', 'install', '--ignore-scripts', '--package-lock'], 'install', timeout=60*20)}
            if result['install_status'] != 0:
                return result
        
        if result['has_build_script']:
            result['did_run_build'] = True
            pbar.set_description(f"{tarball_name} (build)".rjust(50))
            if USE_MINNPM:
                result = {**result, **subproccess_get_result(['npm', 'run', 'build'], 'build', timeout=60*20)}
            else:
                result = {**result, **subproccess_get_result(['npm', 'run', 'build'], 'build', timeout=60*20)}
            if result['build_status'] != 0:
                return result

        if result['has_test_script']:
            result['did_run_test'] = True
            # print(os.getcwd())
            # sys.exit(123)
            pbar.set_description(f"{tarball_name} (test)".rjust(50))
            if USE_MINNPM:
                result = {**result, **subproccess_get_result(['npm', 'run', 'test'], 'test', timeout=60*20)}
            else:
                result = {**result, **subproccess_get_result(['npm', 'run', 'test'], 'test', timeout=60*20)}
            if result['test_status'] != 0:
                return result

    return result


result_records = tarball_helpers.tarball_map(TARBALL_ROOT, test_tarball)
all_columns = [
    'name',
    'root',
    'solve_type',
    'did_run_install', 
    'did_run_build', 
    'did_run_test',
    'skipped_esm', 
    'has_build_script', 
    'has_test_script',
    'install_status',
    'install_stdout',
    'install_stderr',
    'install_time',
    'install_timeout',
    'build_status',
    'build_stdout',
    'build_stderr',
    'build_time',
    'build_timeout',
    'test_status',
    'test_stdout',
    'test_stderr',
    'test_time',
    'test_timeout',
]

result_records = [r for r in result_records if r is not None]

result_df = pd.DataFrame.from_records(result_records, index='name', columns=all_columns)

output = StringIO()
result_df.to_json(output, orient='index', indent=4)
output.seek(0)
print(output.read())