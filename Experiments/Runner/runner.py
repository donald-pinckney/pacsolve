import os
import subprocess
import json
import argparse
import single_runner

def run_single(out, name, maybePath, maybeRepo, maybeTarball, configs, subdirectory, preinstall, postinstall, cleanup, verbosity, timeout):
  options = argparse.Namespace(
    name=name, 
    repo=maybeRepo, 
    tarball=maybeTarball,
    path=maybePath, 
    subdirectory=subdirectory, 
    pre_install=preinstall, 
    post_install=postinstall, 
    out=out, 
    configs=configs,
    cleanup=cleanup,
    verbosity=verbosity,
    timeout=timeout
  )
  single_runner.run(options)

def range_in(idx, r):
  a = r[0]
  b = r[1]

  if a is None and b is None:
    return True
  elif a is None:
    return idx < b
  elif b is None:
    return idx >= a
  else:
    return (a <= idx) and (idx < b)

def filter_projects_range(projects, r):
  return [(idx, p) for idx, p in enumerate(projects.items()) if range_in(idx, r)]

def run(options):
  script_path = os.path.realpath(__file__)
  root_dir = os.path.dirname(os.path.dirname(script_path))
  manifest_path = os.path.join(root_dir, "Datasets", f"{options.dataset}.json")
  out_dir = os.path.join(root_dir, "Output", options.dataset)

  with open(manifest_path) as f:
    manifest = json.load(f)

  
  config_names = options.configs[::2]
  config_values = options.configs[1::2]
  assert len(config_names) == len(config_values)
  configs = list(zip(config_names, config_values))

  all_projects = manifest["projects"]

  if options.all:
    projects = enumerate(all_projects.items())
  elif options.only is not None:
    projects = [(idx, (pk, pv)) for idx, (pk, pv) in enumerate(all_projects.items()) if pk in options.only]
  elif options.range is not None:
    projects = filter_projects_range(all_projects, options.range)
  else:
    raise ValueError("Must specify either --all, --only, or --range")

  
  for project_idx, (project_name, project_options) in projects:
    print(f"Running {project_idx} / {len(all_projects)}")

    run_single(
      out_dir, 
      project_name, 
      project_options.get("path"), 
      project_options.get("git"),
      project_options.get("tarball"),
      configs, 
      "package" if project_options.get("tarball") is not None else project_options.get("subdirectory"), 
      project_options.get("pre-install"), 
      project_options.get("post-install"),
      options.cleanup,
      options.verbosity,
      options.timeout
    )


  

