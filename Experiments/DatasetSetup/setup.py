import pandas as pd
import sqlite3
from tqdm import tqdm
import json

def get_latest_version(con, package_id):
  largeset_non_pre_query = f"""
    SELECT id, major, minor, bug, tarball 
    FROM version 
    WHERE package_id = {package_id} 
      AND prerelease IS NULL 
      AND build IS NULL 
    ORDER BY 
      major DESC, 
      minor DESC, 
      bug DESC LIMIT(1);
  """

  latest_query = f"""
    SELECT 
      version.id AS id, 
      version.major AS major, 
      version.minor AS minor, 
      version.bug AS bug, 
      version.tarball AS tarball
    FROM version 
    JOIN package ON package.latest_version = version.id AND package.id = {package_id}
    LIMIT(1);
  """

  largeset_non_pre_df = pd.read_sql_query(largeset_non_pre_query, con)
  if largeset_non_pre_df.shape[0] > 0:
    return largeset_non_pre_df.iloc[0]
  else:
    return pd.read_sql_query(latest_query, con).iloc[0]


def write_df_to_json(df, dataset_name):
  project_map = dict()
  for i, row in df.iterrows():
    project_map[row['name']] = {"tarball": row['tarball']}
  
  json_output = {'projects': project_map}
  with open(f'Datasets/{dataset_name}.json', 'w') as f:
    json.dump(json_output, f, indent=2)

def prepare_dataset(con, dataset_name, roots_query):
  package_df = pd.read_sql_query(roots_query, con)

  print(f"Looking up highest version number (non prerelese) for each root package")
  package_id_col = []
  name_col = []
  version_id_col = []
  major_col = []
  minor_col = []
  bug_col = []
  tarball_col = []
  for i, row in tqdm(package_df.iterrows()):
    package_id = row['id']
    package_name = row['name']
    version_row = get_latest_version(con, package_id)

    package_id_col.append(package_id)
    name_col.append(package_name)
    version_id_col.append(version_row['id'])
    major_col.append(version_row['major'])
    minor_col.append(version_row['minor'])
    bug_col.append(version_row['bug'])
    tarball_col.append(version_row['tarball'])
  
  version_data_df = pd.DataFrame.from_dict({
    'package_id': package_id_col,
    'name': name_col,
    'version_id': version_id_col,
    'major': major_col,
    'minor': minor_col,
    'bug': bug_col,
    'tarball': tarball_col
  })

  write_df_to_json(version_data_df, dataset_name)


def run(options):
  sql_path = options.sqlite_path
  num_roots = options.num_roots

  con = sqlite3.connect(f"file:{sql_path}?mode=ro", uri=True)

  top_downloads_query = f"""
    SELECT id, name 
    FROM package 
    WHERE name NOT LIKE '@types%' 
    ORDER BY downloads DESC LIMIT({num_roots});
  """

  top_deps_query = f"""
    SELECT package.id AS id, package.name AS name
    FROM package
    JOIN version ON version.id = package.latest_version and package.name NOT LIKE '@types%'
    JOIN version_dependencies ON version.id = version_dependencies.version_id AND version_dependencies.type = 0
    JOIN dependency ON version_dependencies.dependency_id = dependency.id AND dependency.package_id IS NOT NULL
    GROUP BY package.id
    ORDER BY COUNT(*) DESC
    LIMIT({num_roots})
  """

  print(f"Quering for top {num_roots} packages by downloads.")
  prepare_dataset(con, 'nontesting_most_downloads', top_downloads_query)

  print(f"Quering for top {num_roots} packages by number prod deps.")
  prepare_dataset(con, 'nontesting_most_deps', top_deps_query)





