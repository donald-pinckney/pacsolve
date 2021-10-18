import json
import numpy as np
import pandas as pd

def main():
  # 1. Load the list of project names from the JSON file: Datasets/nontesting.json
  
  with open('Datasets/nontesting.json') as f:
    data = json.load(f)
  project_name = []
  for i in data['projects']:
    project_name.append(i)

  # 2. For each project name, load the data in the corresponding npm JSON file
  project_npm = {}
  for name in project_name:
    with open(f'Output/nontesting/results/{name}/npm.json') as f:
      project_npm[name] = json.load(f)

  # 3. For each project name, load the data in the corresponding rosette JSON file
  project_rosette = {}
  for name in project_name:
    with open(f'Output/nontesting/results/{name}/npm.json') as f:
      project_rosette[name] = json.load(f)

  # 4. Make a dataframe in this format:
  # project_name     npm result       npm time       rosette result     rosette time
  #   (string)        (string)        (number)          (string)          (number)
  npm_result = []
  npm_time = []
  rosette_result = []
  rosette_time = []
  for name in project_name:
    npm_result.append(project_npm[name]["install-success"])

    if "install_time" in project_npm[name]:
      npm_time.append(project_npm[name]["install_time"])
    else:
      npm_time.append(np.nan)

    rosette_result.append(project_rosette[name]["install-success"])

    if "install_time" in project_rosette[name]:
        rosette_time.append(project_rosette[name]["install_time"])
    else:
        rosette_time.append(np.nan)

  project_df = pd.DataFrame({'project_name': project_name, 'npm result': npm_result, 'npm time': npm_time, 'rosette result': rosette_result, 'rosette time': rosette_time})


if __name__ == '__main__':
  main()