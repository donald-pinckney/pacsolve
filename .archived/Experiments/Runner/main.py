import argparse
import runner

def range_str(r: str):
  if r is None:
    return None
  else:
    if ':' in r:
      a_str, b_str = r.split(':')
      try:
        a = int(a_str)
      except:
        a = None
      try:
        b = int(b_str)
      except:
        b = None
      
      return (a, b)
    else:
      return (int(r), int(r)+1)

def main():
  # Parse arguments
  parser = argparse.ArgumentParser(description='Script to run experiments')
  parser.add_argument('--verbosity', '-v', default=1, type=int, help='Verbosity level: 0 (silent), 1 (normal), 2 (debug)')
  parser.add_argument('--dataset', required=True, type=str, help='Dataset to use')
  parser.add_argument('--only', default=None, nargs='+', help='The name of projects to test')
  parser.add_argument('--all', action='store_const', const=True, default=False, help='Run all tests')
  parser.add_argument('--range', default=None, type=range_str, help='Index range of projects to test')
  parser.add_argument('--configs', default=[], nargs='+', help='Configurations to run')
  parser.add_argument('--cleanup', action='store_const', const=True, default=False, help='Cleanup work and src dirs')
  parser.add_argument('--timeout', default=600, type=int, help='Timeout to apply in seconds, default 600')
  args = parser.parse_args()
  print(args)
  runner.run(args)

if __name__ == "__main__":
  main()