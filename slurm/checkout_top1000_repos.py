from os import listdir
from os.path import isfile, join
import contextlib
import os
import tempfile
import subprocess
import json
import shutil
import errno
from tqdm import tqdm


TARBALL_ROOT = "top1000tarballs"

def get_tarballs():
    return [f for f in listdir(TARBALL_ROOT) if isfile(join(TARBALL_ROOT, f))]


def tarball_map(f):
    return [f(name) for name in tqdm(get_tarballs())]

@contextlib.contextmanager
def pushd(path):
    previous_dir = os.getcwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(previous_dir)


@contextlib.contextmanager
def unzip_and_pushd(tarball_name):
    tarball_path = join(TARBALL_ROOT, tarball_name)

    with tempfile.TemporaryDirectory() as tmpdirpath:
        subprocess.run(['tar', '-xf', tarball_path, '-C', tmpdirpath], check=True, stderr=subprocess.DEVNULL)
        unzipped_path = join(tmpdirpath, 'package')
        with pushd(unzipped_path):
            yield

def load_json(path):
    with open(path, 'r') as json_file:
        j = json.load(json_file)
    return j


def get_repo_url(tarball_name):
    package_json = {}
    with unzip_and_pushd(tarball_name):
        package_json = load_json('package.json')
    
    repo_url = None
    if "repository" in package_json:
        repo_obj = package_json["repository"]
        if type(repo_obj) == str:
            repo_url = repo_obj
        else:
            if "directory" in repo_obj:
                repo_url = None
            else:
                repo_url = repo_obj["url"]


    if repo_url is not None:
        if "//" not in repo_url:
            if not repo_url.startswith("git@"):
                repo_url = repo_url.replace("github:", "")
                repo_url = f"https://github.com/{repo_url}"

        repo_url = repo_url.replace("git+ssh://", "ssh://")
        repo_url = repo_url.replace("git+https://", "https://")
        repo_url = repo_url.replace("git://", "https://")
        repo_url = repo_url.replace("://git@", "://")
        repo_url = repo_url.replace("ssh://", "https://")
        repo_url = repo_url.replace("://github.com:", "://github.com/")
        repo_url = repo_url.replace("http://", "https://")
        
    return repo_url


def silentremove(filename):
    try:
        os.remove(filename)
    except OSError as e: # this would be "except OSError, e:" before Python 2.6
        if e.errno != errno.ENOENT: # errno.ENOENT = no such file or directory
            raise # re-raise exception if a different error occurred

def prepare_tarball_of_repo(url):
    # print(url)
    with tempfile.TemporaryDirectory() as tmpdirpath:
        tar_name = None
        try:
            with pushd(tmpdirpath):
                subprocess.run(['git', 'clone', url, 'package'], check=True, stderr=subprocess.DEVNULL)
                shutil.rmtree('package/.git')
                silentremove('package/package-lock.json')
                shutil.rmtree('package/node_modules', ignore_errors=True)

                j = load_json(join('package', 'package.json'))
                package_name: str = j["name"]
                tar_name = f"{package_name.replace('/', '_')}.tgz"
                subprocess.run(['tar', '-czf', tar_name, 'package'])
        except Exception as err:
            print(f"FAILED CLONING: {url=}\n{err=}\n\n")
        
        if tar_name is not None:
            shutil.copy(join(tmpdirpath, tar_name), 'top1000tarball_repos')




print("Getting repo URLs from top 1000 tarballs...")
repo_urls = set(tarball_map(get_repo_url))
repo_urls.remove(None)
print(f"Attemping to checkout {len(repo_urls)} repos")
for url in tqdm(repo_urls):
    prepare_tarball_of_repo(url)

