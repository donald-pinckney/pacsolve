import json
import argparse
from json_loading import load_program
from solver.bad_solver import BadSolver


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

  solver = BadSolver()
  result = solver.run_program(prog)

  print(result)
  
  result_json = result.to_json(prog.version_format)

  with open(out_path, 'w') as out_f:
    json.dump(result_json, out_f, indent=2)


if __name__ == "__main__":
  main()