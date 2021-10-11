import argparse
import runner

def main():
  # Parse arguments
  parser = argparse.ArgumentParser(description='Script to run experiments')
  parser.add_argument('--verbosity', '-v', default=1, type=int, help='Verbosity level: 0 (silent), 1 (normal), 2 (debug)')
  parser.add_argument('--dataset', required=True, type=str, help='Dataset to use')
  parser.add_argument('--only', default=None, nargs='+', help='The name of projects to test')
  parser.add_argument('--all', action='store_const', const=True, default=False, help='Run all tests')
  parser.add_argument('--configs', default=[], nargs='+', help='Configurations to run')
  args = parser.parse_args()
  print(args)
  runner.run(args)

if __name__ == "__main__":
  main()