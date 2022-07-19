from os import listdir
from os.path import isfile, join
import contextlib
import os
import tempfile
import subprocess
import json
from tqdm import tqdm


NPM_TARBALL_ROOT = "top1000tarballs"
REPO_TARBALL_ROOT = "top1000tarball_repos"

def get_tarballs(root):
    return [f for f in listdir(root) if isfile(join(root, f))]


def tarball_map(root, f):
    pbar = tqdm(get_tarballs(root)[:5])
    xs = []
    for name in pbar:
        xs.append(f(name, pbar))
    return xs

@contextlib.contextmanager
def pushd(path):
    previous_dir = os.getcwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(previous_dir)


@contextlib.contextmanager
def unzip_and_pushd(root, tarball_name):
    tarball_path = join(root, tarball_name)

    with tempfile.TemporaryDirectory() as tmpdirpath:
        subprocess.run(['tar', '-xf', tarball_path, '-C', tmpdirpath], check=True, stderr=subprocess.DEVNULL)
        unzipped_path = join(tmpdirpath, 'package')
        with pushd(unzipped_path):
            yield

def load_json(path):
    with open(path, 'r') as json_file:
        j = json.load(json_file)
    return j
