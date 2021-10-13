
def main():
  # 1. Load the list of project names from the JSON file: Datasets/nontesting.json
  # 1a. E.g. the list of project names should be ["supports-color", "debug", "semver", etc.]

  # 2. For each project name, load the data in the JSON file at: Output/nontesting/results/<project_name>/npm.json
  
  # 3. For each project name, load the data in the JSON file at: Output/nontesting/results/<project_name>/rosette.json
  
  # 4. Make a dataframe in this format:
  # project_name     npm result       npm time       rosette result     rosette time
  #   (string)        (string)        (number)          (string)          (number)
  
  # where each result row has one of: "success", "failure", "timeout"
  # For example, the first row should be:
  # supports-color     success     26.07438611984253     success       17.688903331756592
  pass

if __name__ == '__main__':
  main()