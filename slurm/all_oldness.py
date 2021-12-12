import os
import subprocess
import sys
import argparse
import re
import itertools
from concurrent.futures import ThreadPoolExecutor

from util import read_json

DUMP_ERRORS = open('/dev/null', 'w')

def strip_node_modules_from_name(package_name):
    parts = package_name.split('/')
    parts.reverse()
    parts = list(itertools.takewhile(lambda s: s != 'node_modules', parts))
    parts.reverse()
    return '/'.join(parts)

def calculate_oldness(package_name, package_lock_path):
    packages = read_json(package_lock_path)['packages']


    # Returns 3 things:
    # - 'error' upon an error
    # - 'ignored' if a node should be ignored on purpose (we found a link but we choose not to follow links)
    # - A float
    def oldness_of_node(node_name, follow_links=True):
        # node_name is an unstripped key in packages.
        metadata = packages[node_name]
        if 'link' in metadata and metadata['link']:
            if follow_links:
                return oldness_of_node(metadata['resolved'], follow_links=follow_links)
            else:
                return 'ignored'
        elif 'version' not in metadata:
            print(f'Error (ignored): no version for {node_name} in {package_lock_path}', file=sys.stderr)
            return 'error'
        else:
            version = metadata['version']
            stripped_name = strip_node_modules_from_name(node_name)
            try:
                oldness = subprocess.check_output([
                        '../version-oldness/version-oldness.sh', 
                        stripped_name, 
                        version],
                        stderr=DUMP_ERRORS
                    ).decode(
                        'utf-8', 
                        errors='ignore'
                    ).strip()
                return float(oldness)
            except KeyboardInterrupt as e:
                raise e
            except BaseException as e:
                print(f'Error (ignored): version-oldness {node_name} {version}', file=sys.stderr)
                return 'error'


    aggregate_oldness = 0
    num_packages = 0

    for name in packages.keys():
        oldness_maybe = oldness_of_node(name)
        
        if oldness_maybe == 'error':
            pass # we already logged the error
        elif oldness_maybe == 'ignored':
            print(f'Warning (ignored): choose to ignore {name} in {package_lock_path}', file=sys.stderr)
        else:
            aggregate_oldness += oldness_maybe
            num_packages += 1

    if num_packages == 0:
        return f'{package_name},0'

    return f'{package_name},{aggregate_oldness / num_packages}'

def check_and_calc_oldness(root, package_name):
    package_lock_path = os.path.join(root, package_name, 'package',
        'node_modules', '.package-lock.json')
    experiment_status_path = os.path.join(root, package_name, 'package', 'experiment.json')
    if not os.path.isfile(experiment_status_path):
        return None
    if read_json(experiment_status_path)['status'] != 'success':
        return None
    if os.path.isfile(package_lock_path):
        return calculate_oldness(package_name, package_lock_path)
    else:
        return f'{package_name},0'


def calculate_oldness_all(root):
    all_packages = os.listdir(root)
    print('Package,Oldness')
    with ThreadPoolExecutor(max_workers=250) as executor:
        for r in executor.map(lambda p: check_and_calc_oldness(root, p), all_packages):
            if r is not None:
                print(r)


def main():
    parser = argparse.ArgumentParser(description='Aggregate oldness data')
    parser.add_argument('input_dir', help='Directory of installed packages')
    args = parser.parse_args()
    calculate_oldness_all(args.input_dir)


if __name__ == '__main__':
    main()
