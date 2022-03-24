import argparse
import setup

def main():
  # Parse arguments
  parser = argparse.ArgumentParser(description='Script to setup experiment dataset')
  parser.add_argument('--sqlite-path', required=True, help='The path to the SQLite database')
  parser.add_argument('--num-roots', default=1000, help='The number of root packages (sorted by number of downloads). Default = 1000', type=int)
  args = parser.parse_args()
  setup.run(args)

if __name__ == "__main__":
  main()