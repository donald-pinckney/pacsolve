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

TARBALL_ROOT = sys.argv[1].rstrip("/")


def subproccess_get_result(command, name):
    start = time.time()
    try:
        completed = subprocess.run(command, capture_output=True, text=True, stdin=subprocess.DEVNULL, timeout=60*20)
    except subprocess.TimeoutExpired:
        dt = time.time() - start
        return {f'{name}_status': None, f'{name}_stdout': None, f'{name}_stderr': None, f'{name}_time': dt, f'{name}_timeout': True}
    dt = time.time() - start
    return {f'{name}_status': completed.returncode, f'{name}_stdout': completed.stdout, f'{name}_stderr': completed.stderr, f'{name}_time': dt, f'{name}_timeout': False}

def test_tarball(tarball_name, pbar):
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
        

        result['did_run_install'] = True
        pbar.set_description(f"{tarball_name} (install)".rjust(50))
        result = {**result, **subproccess_get_result(['npm', 'install', '--ignore-scripts'], 'install')}
        if result['install_status'] != 0:
            return result
        
        if result['has_build_script']:
            result['did_run_build'] = True
            pbar.set_description(f"{tarball_name} (build)".rjust(50))
            result = {**result, **subproccess_get_result(['npm', 'run', 'build'], 'build')}
            if result['build_status'] != 0:
                return result

        if result['has_test_script']:
            result['did_run_test'] = True
            pbar.set_description(f"{tarball_name} (test)".rjust(50))
            result = {**result, **subproccess_get_result(['npm', 'run', 'test'], 'test')}
            if result['test_status'] != 0:
                return result

    return result


result_records = tarball_helpers.tarball_map(TARBALL_ROOT, test_tarball)
all_columns = [
    'name',
    'root',
    'did_run_install', 
    'did_run_build', 
    'did_run_test', 
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
result_df.to_json(output, orient='index')
output.seek(0)
print(output.read())