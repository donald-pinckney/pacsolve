import json
import argparse
from json_loading import load_program


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('--in-json', required=True)
  parser.add_argument('--out-json', required=True)
  args = parser.parse_args()
  in_path = args.in_json
  out_path = args.out_json

  with open(in_path, 'r') as in_f:
    in_data = json.load(in_f)

  prog = load_program(in_data)

  print()
  print(repr(prog))

  # result = prog.run()
  
  # result_json = result.to_json()

  # with open(out_path, 'w') as out_f:
  #   json.dump(result_json, out_f)


if __name__ == "__main__":
  main()