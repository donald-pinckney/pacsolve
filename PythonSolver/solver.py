import json
import argparse

def parse_program(j):
  pass
  
def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('--in-json', required=True)
  parser.add_argument('--out-json', required=True)
  args = parser.parse_args()
  in_path = args.in_json
  out_path = args.out_json

  with open(in_path, 'r') as in_f:
    in_data = json.load(in_f)

  prog = parse_program(in_data)

  result = prog.run()
  
  result_json = result.to_json()

  with open(out_path, 'w') as out_f:
    json.dump(result_json, out_f)


if __name__ == "__main__":
  main()