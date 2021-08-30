import os
import subprocess
import json
import argparse
import single_runner

# parser = argparse.ArgumentParser(description='Runs the install process for a given repo')
#   parser.add_argument('--name', help='The unique name of the project to run')
#   parser.add_argument('--repo', help='The URL to the repo to clone')
#   parser.add_argument('--path', help='The path to a JS project')
#   parser.add_argument('--pre-install', help='The pre-install command to run')
#   parser.add_argument('--post-install', help='The post-install command to run')
#   parser.add_argument('--out', help='The output directory for all lockfiles')
#   parser.add_argument('--configs', nargs='+', help='The list of install configurations to try')
#   args = parser.parse_args()

def run_single(out, name, maybePath, maybeRepo, configs, subdirectory, preinstall, postinstall, verbosity):
  options = argparse.Namespace(
    name=name, 
    repo=maybeRepo, 
    path=maybePath, 
    subdirectory=subdirectory, 
    pre_install=preinstall, 
    post_install=postinstall, 
    out=out, 
    configs=configs,
    verbosity=verbosity
  )
  single_runner.run(options)

def run(options):
  script_path = os.path.realpath(__file__)
  root_dir = os.path.dirname(os.path.dirname(script_path))
  manifest_path = os.path.join(root_dir, "Dataset", "manifest.json")
  out_dir = os.path.join(root_dir, "Output")

  with open(manifest_path) as f:
    manifest = json.load(f)

  configs = manifest["configs"]
  all_projects = manifest["projects"]

  if not options.all:
    projects = {p: all_projects[p] for p in options.only}
  else:
    projects = all_projects
  
  for project_name, project_options in projects.items():
    run_single(
      out_dir, 
      project_name, 
      project_options.get("path"), 
      project_options.get("git"), 
      configs, 
      project_options.get("subdirectory"), 
      project_options.get("pre-install"), 
      project_options.get("post-install"),
      options.verbosity
    )


  

