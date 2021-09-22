import json
from typing import Dict
import requests
from tqdm.contrib.concurrent import process_map 
import os
import sys
import time


def download_packument_json(name):
  url = f'https://registry.npmjs.org/{name}'
  r = requests.get(url)
  return r.json()

def download_download_count_json(name):
  url = f'https://api.npmjs.org/downloads/point/2021-08-01:2021-08-31/{name}'
  r = requests.get(url)
  return r.json()

def retry(f, n):
  def wrapper(*args, **kwargs):
    the_err = None
    for i in range(n):
      try:
        return f(*args, **kwargs)
      except Exception as e:
        the_err = e
        # sleep for a bit
        if i != n - 1:
          time.sleep(5 * (i + 1))
        pass
    raise the_err

  return wrapper


def process_data(packument: Dict, download_json):
  if 'dist-tags' not in packument:
    return None

  downloads = download_json.get('downloads')
  
  times_dict = packument['time']
  modified = times_dict['modified']
  created = times_dict['created']
  del times_dict['modified']
  del times_dict['created']


  return {
    'name': packument['name'],
    'dist-tags': packument['dist-tags'],
    'modified': modified,
    'created': created,
    'version-times': times_dict,
    'downloads_august_2021': downloads,
    'versions': [k for k in packument['versions']],
    'maintainers': packument['maintainers'],
    'description': packument.get('description'),
    'repository': packument.get('repository'),
    'bugs': packument.get('bugs'),
    'license': packument.get('license'),
  }

def get_name_metadata(name):
  try:
    packument = retry(download_packument_json, 5)(name)
    download_json = retry(download_download_count_json, 5)(name)
  except Exception as e:
    print(f'Failed to download {name} 5 times. Error:', file=sys.stderr)
    print(e, file=sys.stderr)
    return None
  
  try:
    return process_data(packument, download_json)
  except Exception as e:
    print(f'Error processing {name}:', file=sys.stderr)
    raise e

def non_process_map(f, xs):
  return list(map(f, xs))


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



  print("Parsing replacate JSON", file=sys.stderr)

  with open(raw_file) as f:
    db = json.load(f)

  print("Getting package names", file=sys.stderr)

  rows = db['rows']
  package_names = [r['key'] for r in rows]

  # package_names = package_names[:30]

  package_names = job_chunk(package_names, n_jobs, job_id)

  print("About to start process_map", file=sys.stderr)

  package_metadata = process_map(get_name_metadata, package_names, max_workers=os.cpu_count() * 3, chunksize=16)

  print("Converting to dictionary", file=sys.stderr)

  package_data = dict(zip(package_names, package_metadata))
  package_data = {k: v for k, v in package_data.items() if v is not None}

  # with open('all_package_stats.json', 'w') as f:

  print("Writing JSON", file=sys.stderr)

  print(json.dumps(package_data))
  print()

if __name__ == "__main__":
  main()