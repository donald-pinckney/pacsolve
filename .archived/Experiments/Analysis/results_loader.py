import json
import numpy as np
import pandas as pd

def load_data(dataset_name):
  # 1. Load the list of project names from the JSON file: Datasets/{dataset_name}.json
  
  with open(f'../Datasets/{dataset_name}.json') as f:
    data = json.load(f)
  project_name = []
  for i in data['projects']:
    project_name.append(i)

  # 2. For each project name, load the data in the corresponding npm JSON file
  project_npm = {}
  for name in project_name:
    with open(f'../Output/{dataset_name}/results/{name}/npm.json') as f:
      project_npm[name] = json.load(f)

  # 3. For each project name, load the data in the corresponding rosette JSON file
  project_rosette = {}
  for name in project_name:
    with open(f'../Output/{dataset_name}/results/{name}/rosette.json') as f:
      project_rosette[name] = json.load(f)

  # 4. Make a dataframe in this format:
  # project_name     npm success      npm time       npm solve       rosette success     rosette time     rosette solve
  #   (string)        (string)        (number)     (dict or none)       (string)          (number)        (dict or none)
  npm_success = []
  npm_time = []
  npm_solve = []
  npm_error = []
  rosette_success = []
  rosette_time = []
  rosette_solve = []
  rosette_error = []
  for name in project_name:
    npm_success.append(project_npm[name]["install-success"])
    npm_time.append(project_npm[name]["install_time"])
    npm_solve.append(project_npm[name].get("installed_deps"))
    npm_error.append(project_npm[name].get("error"))
    
    rosette_success.append(project_rosette[name]["install-success"])
    rosette_time.append(project_rosette[name]["install_time"])
    rosette_solve.append(project_rosette[name].get("installed_deps"))
    rosette_error.append(project_rosette[name].get("error"))

  project_df = pd.DataFrame({
    'project_name': project_name, 
    'npm success': npm_success, 
    'npm time': npm_time, 
    'npm solve': npm_solve,
    'npm error': npm_error,
    'rosette success': rosette_success, 
    'rosette time': rosette_time,
    'rosette solve': rosette_solve,
    'rosette error': rosette_error
  })
  return project_df
