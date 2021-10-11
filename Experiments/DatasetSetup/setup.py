import pandas as pd
import sqlite3
from tqdm import tqdm
import json

def get_latest_version(con, package_id):
  query = f"""
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

  return pd.read_sql_query(query, con).iloc[0]


def write_df_to_json(df):
  project_map = dict()
  for i, row in df.iterrows():
    project_map[row['name']] = {"tarball": row['tarball']}
  
  json_output = {'projects': project_map}
  with open('Datasets/nontesting.json', 'w') as f:
    json.dump(json_output, f, indent=2)

def run(options):
  sql_path = options.sqlite_path
  num_roots = options.num_roots

  con = sqlite3.connect(f"file:{sql_path}?mode=ro", uri=True)
  print(f"Quering for top {num_roots} packages by downloads.")
  package_df = pd.read_sql_query(f"SELECT id, name FROM package ORDER BY downloads DESC LIMIT({num_roots});", con)

  print(f"Looking up highest version number (non prerelese) for each top package")
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

  write_df_to_json(version_data_df)

