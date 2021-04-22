#!/usr/bin/env python
# Learn more: https://github.com/kennethreitz/setup.py

from codecs import open
import os

from setuptools import setup

here = os.path.abspath(os.path.dirname(__file__))

about = {}
with open(os.path.join(here, "pkg_src", '__metadata__.py'), 'r', 'utf-8') as f:
    exec(f.read(), about)


package_name = about["__name__"]
package_version = about["__version__"]
package_dependencies = about["__dependencies__"]

setup(
  name=package_name,
  version=package_version,
  packages=[package_name],
  package_dir={package_name: 'pkg_src'},
  install_requires=package_dependencies,    
)
