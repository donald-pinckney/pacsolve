from os.path import join
import os
import tempfile
import subprocess
import shutil
import errno
from tqdm import tqdm
import tarball_helpers



def get_repo_url(tarball_name, _pbar):
    package_json = {}
    with tarball_helpers.unzip_and_pushd(tarball_helpers.NPM_TARBALL_ROOT, tarball_name):
        package_json = tarball_helpers.load_json('package.json')
    
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
            with tarball_helpers.pushd(tmpdirpath):
                subprocess.run(['git', 'clone', url, 'package'], check=True, stderr=subprocess.DEVNULL)
                shutil.rmtree('package/.git')
                silentremove('package/package-lock.json')
                shutil.rmtree('package/node_modules', ignore_errors=True)

                j = tarball_helpers.load_json(join('package', 'package.json'))
                package_name: str = j["name"]
                tar_name = f"{package_name.replace('/', '_')}.tgz"
                subprocess.run(['tar', '-czf', tar_name, 'package'])
        except Exception as err:
            print(f"FAILED CLONING: {url=}\n{err=}\n\n")
        
        if tar_name is not None:
            shutil.copy(join(tmpdirpath, tar_name), 'top1000tarball_repos')




print("Getting repo URLs from top 1000 tarballs...")
repo_urls = set(tarball_helpers.tarball_map(tarball_helpers.NPM_TARBALL_ROOT, get_repo_url))
repo_urls.remove(None)
print(f"Attemping to checkout {len(repo_urls)} repos")
for url in tqdm(repo_urls):
    prepare_tarball_of_repo(url)

