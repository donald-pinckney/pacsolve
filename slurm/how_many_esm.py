import sys
import numpy as np

import tarball_helpers

GLOBAL_TESTING_PREFIX = "/mnt/data/donald/npm_global_testing_prefix"
TARBALL_ROOT = sys.argv[1].rstrip("/")
USE_MINNPM = True


def is_esm(tarball_name, pbar):
    with tarball_helpers.unzip_and_pushd(TARBALL_ROOT, tarball_name):
        j = tarball_helpers.load_json('package.json')
        return "type" in j and j["type"] == "module"



which_esm = tarball_helpers.tarball_map(TARBALL_ROOT, is_esm)
print(np.array(which_esm).sum())
