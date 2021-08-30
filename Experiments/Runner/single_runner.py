import os
import subprocess
import json
import time
from contextlib import contextmanager


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


LOG_INDENT = 0
CURRENT_LOG_LEVEL = 0
CHOSEN_LOG_LEVEL = 1

def log_indent():
  global LOG_INDENT
  LOG_INDENT += 1

def log_deindent():
  global LOG_INDENT
  LOG_INDENT -= 1

def should_log():
  global CURRENT_LOG_LEVEL
  global CHOSEN_LOG_LEVEL
  return CURRENT_LOG_LEVEL < CHOSEN_LOG_LEVEL

def log_bullet(message, bullet=None, **kwargs):
  if not should_log():
    return False
  
  bullets = ["*", "-", "+"]
  if bullet is None:
    bullet = bullets[LOG_INDENT % len(bullets)]
  print("{}{} {}".format("  " * LOG_INDENT, bullet, message), **kwargs)
  return True

@contextmanager
def log_section(section, level=0):
  global CURRENT_LOG_LEVEL
  global CHOSEN_LOG_LEVEL

  if not should_log():
    try:
      yield
    finally:
      pass
  else:
    old_log_level = CURRENT_LOG_LEVEL
    CURRENT_LOG_LEVEL = level

    did_log = log_bullet(section)
    if did_log:
      log_indent()
      try:
        yield
      finally:
        log_deindent()
        CURRENT_LOG_LEVEL = old_log_level
    else:
      try:
        yield
      finally:
        CURRENT_LOG_LEVEL = old_log_level
      

def run_subprocess(cmd, **args):
  if args.get('log', False):
    command_str = " ".join(cmd) if isinstance(cmd, list) else cmd
    did_log = log_bullet(command_str + " ", ">", end='', flush=True)
    del args['log']
  else:
    did_log = False

  if args.get('silent', False):
    del args['silent']
    args['stdout'] = subprocess.DEVNULL
    args['stderr'] = subprocess.STDOUT
  
  try:
    t0 = time.time()
    ret = subprocess.run(cmd, **args)
    dt = time.time() - t0
    if did_log:
      print("✅ ({:.2f} s)".format(dt))
    return ret
  except subprocess.CalledProcessError as e:
    dt = time.time() - t0
    if did_log:
      print("❌ ({:.2f} s)".format(dt))
    raise 


def path_join_flat(*args):
  return os.path.join(*[x for x in args if x is not None])

def prepare_out_dir(out_dir, name, run_configs, subdirectoryMaybe):
  source_path = os.path.join(out_dir, "src", name)
  work_path = os.path.join(out_dir, "work", name)
  results_path = os.path.join(out_dir, "results", name)
  
  # Create source_path directory, and clear it if it already exists
  run_subprocess(["rm", "-rf", source_path], check=False)
  os.makedirs(source_path)

  # Create work_path directory, and clear it if it already exists
  run_subprocess(["rm", "-rf", work_path], check=False)
  os.makedirs(work_path)

  # Create results_path directory, and clear it if it already exists
  run_subprocess(["rm", "-rf", results_path], check=False)
  os.makedirs(results_path)

  result_files = [os.path.join(results_path, '{}.json'.format(config_name)) for config_name in run_configs]
  work_dirs = [os.path.join(work_path, config_name) for config_name in run_configs]
  for wd in work_dirs:
    os.makedirs(wd, exist_ok=False)
  
  return source_path, work_dirs, result_files


def prepare_src_dir(src_dir, config):
  if config.path is None:
    # Clone from git
    run_subprocess(["git", "clone", config.repo, src_dir], check=True, silent=True, log=True)
  else:
    # Copy from local directory
    run_subprocess(["cp", "-r", config.path, src_dir], check=True, log=True)

def copy_to_work_dir(src_dir, work_dir):
  src = os.path.join(src_dir, ".")
  run_subprocess(["cp", "-r", src, work_dir], check=True, log=True)

def preinstall(wd, options):
  with log_section("Pre-install", level=1):
    if options.pre_install is not None:
      run_subprocess(options.pre_install, shell=True, cwd=wd, check=True, capture_output=True, log=True)
    
    run_subprocess(["rm", "-rf", "package-lock.json", "node_modules/"], cwd=wd, log=True)

def install(wd, config):
  with log_section("Install"):
    if config == 'npm':
      install_command = ["npm", "install"]
    elif config == 'rosette-npm-num_packages':
      install_command = ["npm", "install", "--rosette"]
    else:
      raise Exception("Unknown test config: {}".format(config))

    try:
      t0 = time.time()
      run_subprocess(install_command, cwd=wd, check=True, capture_output=True, log=True)
      t1 = time.time()
      return t1 - t0

    except subprocess.CalledProcessError as e:
      raise TestingError("install", e.cmd, e.returncode, e.stdout, e.stderr)

def postinstall(wd, options):
  with log_section("Post-install"):
    if options.post_install is not None:
      try:
        run_subprocess(options.post_install, shell=True, cwd=wd, check=True, capture_output=True, log=True)
      except subprocess.CalledProcessError as e:
        raise TestingError("post-install", e.cmd, e.returncode, e.stdout, e.stderr)

def copy_result(wd, result_file, install_success, install_time, error):
  if install_success:
    with open(os.path.join(wd, 'package-lock.json'), 'r') as f:
      lockfile = json.load(f)
    if error is None:
      result = {
        'install-success': True, 
        'install_time': install_time, 
        'post-install-success': True,
        'lockfile': lockfile
      }
    else:
      result = {
        'install-success': True, 
        'install_time': install_time, 
        'post-install-success': False, 
        'lockfile': lockfile, 
        'error': error.toJSON()
      }
  else:
    result = {'install-success': False, 'error': error.toJSON()}
    
  with open(result_file, 'w') as f:
    json.dump(result, f, indent=2)
  
def run(options):
  global CHOSEN_LOG_LEVEL
  CHOSEN_LOG_LEVEL = options.verbosity
  
  with log_section("Project: {}".format(options.name)):
    with log_section("Acquire Source", level=2):
      run_configs = options.configs
      source_dir, work_dirs, result_files = prepare_out_dir(options.out, options.name, run_configs, options.subdirectory)

      prepare_src_dir(source_dir, options)
    
    for config, wd, rf in zip(run_configs, work_dirs, result_files):
      with log_section("Run configuration: {}".format(config)):
        with log_section("Setup working directory ({})".format(wd), level=2):
          copy_to_work_dir(source_dir, wd)
          wd = path_join_flat(wd, options.subdirectory)

        preinstall(wd, options)
        try:
          install_time = install(wd, config)
        except TestingError as e:
          copy_result(wd, rf, False, None, e)
          continue

        try:
          postinstall(wd, options)
        except TestingError as e:
          copy_result(wd, rf, True, install_time, e)
          continue
          
        copy_result(wd, rf, True, install_time, None)
  
