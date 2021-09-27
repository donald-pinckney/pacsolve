import json
from typing import Dict
import requests
from tqdm.contrib.concurrent import process_map 
from tqdm import tqdm
# import os
import sys
# import time
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.util.retry import Retry


def download_download_count_json(name, session):
  url = f'https://api.npmjs.org/downloads/point/2021-08-01:2021-08-31/{name}'
  try:
    r = session.get(url)
    return r.json()
  except Exception as e:
    print(f'Failed to download {name}. Error:', file=sys.stderr)
    print(e, file=sys.stderr)
    return None

# def non_process_map(f, xs, env):
#   return list(map(lambda x: f(x, env), tqdm(xs)))


# def job_chunk(xs, n_jobs, job_id):
#   l = len(xs)
#   chunk_size = l // n_jobs
#   last_extra = l % n_jobs
#   my_chunk_size = chunk_size + (last_extra if job_id == n_jobs - 1 else 0)
#   start = job_id * chunk_size
#   end = start + my_chunk_size
#   print(f'Running chunk {start}:{end} for job id {job_id}', file=sys.stderr)
#   return xs[start:end]

def batches(xs):
  chunk_size = 128
  return [",".join(xs[i:i+chunk_size]) for i in range(0, len(xs), chunk_size)]

def split_scoped(names):
  scoped = []
  nonscoped = []
  for name in names:
    if '@' in name:
      scoped.append(name)
    else:
      nonscoped.append(name)
  return nonscoped, scoped

def job_chunk(xs, n_jobs, job_id):
  l = len(xs)
  chunk_size = l // n_jobs
  last_extra = l % n_jobs
  my_chunk_size = chunk_size + (last_extra if job_id == n_jobs - 1 else 0)
  start = job_id * chunk_size
  end = start + my_chunk_size
  print(f'Running chunk {start}:{end} for job id {job_id}', file=sys.stderr)
  return xs[start:end]

def main():
  # raw_file = 'all_packages_raw.json'
  # os.system(f'wget -O {raw_file} https://replicate.npmjs.com/_all_docs')

  raw_file = sys.argv[1]
  n_jobs = int(sys.argv[2])
  job_id = int(sys.argv[3])


  print("Parsing replicate JSON", file=sys.stderr)

  with open(raw_file) as f:
    db = json.load(f)

  print("Getting package names", file=sys.stderr)

  rows = db['rows']
  package_names = [r['key'] for r in rows]

  # package_names = package_names[:300]


  nonscoped, scoped = split_scoped(package_names)
  nonscoped_batches = batches(nonscoped)
  
  all_names = nonscoped_batches + scoped
  all_names = job_chunk(all_names, n_jobs, job_id)

  
  session = requests.Session()
  retry = Retry(connect=8, backoff_factor=0.5)
  adapter = HTTPAdapter(max_retries=retry)
  session.mount('http://', adapter)
  session.mount('https://', adapter)

  download_jsons = [download_download_count_json(n, session) for n in tqdm(all_names)]


  print("Writing JSON", file=sys.stderr)

  print(json.dumps(download_jsons))
  print()

  # package_metadata = non_process_map(get_name_metadata, package_names, session)

  # print("Converting to dictionary", file=sys.stderr)

  # package_data = dict(zip(package_names, package_metadata))
  # package_data = {k: v for k, v in package_data.items() if v is not None}

  # # with open('all_package_stats.json', 'w') as f:

  # print("Writing JSON", file=sys.stderr)

  # print(json.dumps(package_data))
  # print()

if __name__ == "__main__":
  main()