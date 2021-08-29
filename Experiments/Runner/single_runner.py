import os
import subprocess
import json


class TestingError(Exception):
  def __init__(self, stage, command, retcode, stdout, stderr) -> None:
    self.stage = stage
    self.command = command
    self.retcode = retcode
    self.stdout = stdout
    self.stderr = stderr
    super().__init__("{}: {} returned code {}. stdout: {}, stderr: {}".format(self.stage, self.command, self.retcode, self.stdout, self.stderr))

  def toJSON(self):
    if isinstance(self.stdout, bytes):
      stdout = self.stdout.decode("utf-8")
    else:
      stdout = self.stdout
    
    if isinstance(self.stderr, bytes):
      stderr = self.stderr.decode("utf-8")
    else:
      stderr = self.stderr

    return {"stage": self.stage, "command": self.command, "retcode": self.retcode, "stdout": stdout, "stderr": stderr}

def prepare_out_dir(out_dir, name, run_configs):
  source_path = os.path.join(out_dir, "src", name)
  work_path = os.path.join(out_dir, "work", name)
  results_path = os.path.join(out_dir, "results", name)
  
  # Create source_path directory, and clear it if it already exists
  subprocess.run(["rm", "-rf", source_path], check=False)
  os.makedirs(source_path)

  # Create work_path directory, and clear it if it already exists
  subprocess.run(["rm", "-rf", work_path], check=False)
  os.makedirs(work_path)

  # Create results_path directory, and clear it if it already exists
  subprocess.run(["rm", "-rf", results_path], check=False)
  os.makedirs(results_path)

  result_files = [os.path.join(results_path, '{}.json'.format(config_name)) for config_name in run_configs]
  work_dirs = [os.path.join(work_path, config_name) for config_name in run_configs]
  for wd in work_dirs:
    os.makedirs(wd, exist_ok=False)
  
  return source_path, work_dirs, result_files


def prepare_src_dir(src_dir, config):
  if config.path is None:
    # Clone from git
    subprocess.run(["git", "clone", config.repo, src_dir], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
  else:
    # Copy from local directory
    subprocess.run(["cp", "-r", config.path, src_dir], check=True)

def copy_to_work_dir(src_dir, work_dir):
  src = os.path.join(src_dir, ".")
  subprocess.run(["cp", "-r", src, work_dir], check=True)

def preinstall(wd, options):
  if options.pre_install is not None:
    subprocess.run(options.pre_install, shell=True, cwd=wd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
  
  subprocess.run(["rm", "-rf", "package-lock.json", "node_modules/"], cwd=wd)

def install(wd, config):
  if config == 'npm':
    install_command = ["npm", "install"]
  elif config == 'rosette-npm-num_packages':
    install_command = ["npm", "install", "--rosette"]
  else:
    raise Exception("Unknown test config: {}".format(config))

  try:
    subprocess.run(install_command, cwd=wd, check=True, capture_output=True)
  except subprocess.CalledProcessError as e:
    raise TestingError("install", e.cmd, e.returncode, e.stdout, e.stderr)

def postinstall(wd, options):
  if options.post_install is not None:
    try:
      subprocess.run(options.post_install, shell=True, cwd=wd, check=True, capture_output=True)
    except subprocess.CalledProcessError as e:
      raise TestingError("post-install", e.cmd, e.returncode, e.stdout, e.stderr)

def copy_result(wd, result_file, install_success, error):
  if install_success:
    with open(os.path.join(wd, 'package-lock.json'), 'r') as f:
      lockfile = json.load(f)
    if error is None:
      result = {'install-success': True, 'lockfile': lockfile, 'post-install-success': True}
    else:
      result = {'install-success': True, 'lockfile': lockfile, 'post-install-success': False, 'error': error.toJSON()}
  else:
    result = {'install-success': False, 'error': error.toJSON()}
    
  with open(result_file, 'w') as f:
    json.dump(result, f, indent=2)
  
def run(options):
  run_configs = options.configs
  source_dir, work_dirs, result_files = prepare_out_dir(options.out, options.name, run_configs)

  prepare_src_dir(source_dir, options)
  
  for config, wd, rf in zip(run_configs, work_dirs, result_files):
    copy_to_work_dir(source_dir, wd)
    preinstall(wd, options)
    try:
      install(wd, config)
    except TestingError as e:
      copy_result(wd, rf, False, e)
      continue

    try:
      postinstall(wd, options)
    except TestingError as e:
      copy_result(wd, rf, True, e)
      continue
      
    copy_result(wd, rf, True, None)
  
