import json
import os

def get_download_pairs(j):
  keys = set(j.keys())
  if keys == set(['downloads', 'start', 'end', 'package']):
    return [(j['package'], j['downloads'])]
  elif keys == set(['error']):
    return []
  else:
    return [pr for inner in j.values() 
               if inner is not None 
               for pr in get_download_pairs(inner)]
  

def main():
  all_jsons = []

  dir = 'downloads-outputs/'
  for file in os.scandir(dir):
    if file.path.endswith('.json'):
      print(f"Loading {file.path}")
      with open(file.path) as f:
        all_jsons += json.load(f)
  
  dict_pairs = [pr for j in all_jsons for pr in get_download_pairs(j)]
  download_dict = dict(dict_pairs)

  with open('all_downloads.json', 'w') as f:
    json.dump(download_dict, f)

if __name__ == "__main__":
  main()