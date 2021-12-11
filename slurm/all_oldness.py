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

    aggregate_oldness = 0
    num_packages = 0

    for name, metadata in packages.items():
        unstripped_name = name
        name = strip_node_modules_from_name(name)
        if 'version' not in metadata:
            if 'link' not in metadata:
                print(f'Error (ignored): no version for {unstripped_name} in {package_lock_path}', file=sys.stderr)
            continue
        version = metadata['version']
        try:
            oldness = subprocess.check_output([
                    '../version-oldness/version-oldness.sh', 
                    name, 
                    version],
                    stderr=DUMP_ERRORS
                ).decode(
                    'utf-8', 
                    errors='ignore'
                ).strip()
            aggregate_oldness += float(oldness)
            num_packages += 1
        except KeyboardInterrupt as e:
            raise e
        except BaseException as e:
            print(f'Error (ignored): version-oldness {name} {version}', file=sys.stderr)

    if num_packages == 0:
        return f'{package_name},0'

    return f'{package_name},{aggregate_oldness / num_packages}'

def check_and_calc_oldness(root, package_name):
    package_lock_path = os.path.join(root, package_name, 'package',
        'node_modules', '.package-lock.json')
    if os.path.isfile(package_lock_path):
        return calculate_oldness(package_name, package_lock_path)
    else:
        return f'{package_name},0'
    print(f'Failed on {package_lock_path}:\n{e}', file=sys.stderr)
    return f'{package_name},'


def calculate_oldness_all(root):
    all_packages = os.listdir(root)
    print('Package,Oldness')
    with ThreadPoolExecutor(max_workers=250) as executor:
        for r in executor.map(lambda p: check_and_calc_oldness(root, p), all_packages):
            print(r)


def main():
    parser = argparse.ArgumentParser(description='Aggregate oldness data')
    parser.add_argument('input_dir', help='Directory of installed packages')
    args = parser.parse_args()
    calculate_oldness_all(args.input_dir)


if __name__ == '__main__':
    main()
