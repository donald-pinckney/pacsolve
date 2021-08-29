import argparse
import runner

def main():
  # Parse arguments
  parser = argparse.ArgumentParser(description='Runs the install process for a given repo')
  parser.add_argument('--only', default=None, nargs='+', help='The name of projects to test')
  parser.add_argument('--all', action='store_const', const=True, default=False, help='Run all tests')
  args = parser.parse_args()
  runner.run(args)

if __name__ == "__main__":
  main()