use serde::Deserialize;
use serde_json::Value;
use std::collections::HashMap;
use std::fs::File;
use crate::dsl;


#[derive(Deserialize, Debug)]
pub struct InputQuery {
  // A listing of all relevant named packages & versions & dependencies
  registry: Vec<Package>, 
  // The dependencies of the "context" node, that is, the dependencies
  // of the place we are running `npm install` from.
  context_dependencies: Dependencies,
  // Some options for the query.
  options: QueryOptions,
  // The arbitrary functions given in a DSL
  functions: ArbitraryFunctionsMap,
}

impl InputQuery {
  pub fn from_path(path: &str) -> InputQuery {
    let input_file = File::open(path).expect(&format!("Failed to open input path: {}", path));
    serde_json::from_reader(input_file).expect("Failed to parse input JSON")
  }
}

#[derive(Deserialize, Debug)]
struct Package {
  // The name of the package
  package: String,
  // List of all the specific versions of a package
  versions: Vec<VersionOfAPackage>
}

#[derive(Deserialize, Debug)]
struct VersionOfAPackage {
  // An arbitrary JSON blob encoding the version number, 
  // but it must be deserializable by the
  // "versionDeserialize" function (see below) 
  version: Value, // This has "type" JsonVersion

  // The dependencies of this version of the package
  dependencies: Dependencies
}

type Dependencies = Vec<Dependency>;

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
struct Dependency {
  // The name of the package to depend on,
  // refers to `package_name` field in `Package`.
  package_to_depend_on: String,

  // An arbitrary JSON blob encoding the version constraint of the dependency.
  // It must be readable by the "constraintInterpretation" function (see below).
  constraint: Value // This has "type" JsonConstraint
}

#[derive(Deserialize, Debug)]
struct QueryOptions {
  // currently is always set to 1. 
  // remove in final version
  max_duplicates: i32, 
  // Whether or not to add a constraint
  // that the resolution graph is acyclic
  // Use false for npm!
  check_acyclic: bool,
  // A list of prioritized minimization criteria.
  // Currently the only supported criteria is: "graph-num-vertices"
  minimization_criteria: Vec<String>,

}


// Each function has a name, as given in the hash map
// There are a few special names which MUST exist in the hash map:
//   - "constraintInterpretation": 
//      This function must have type JsonConstrint -> (sym Version -> Bool),
//      and is used by the solver to evaluate version constraint satisfaction
//   - "consistency":
//      This function must have type Version * Version -> Bool,
//      and is used by the solver to check version co-occurrence consistency
//   - "versionDeserialize":
//      This function has type JsonVersion -> RosetteVersion,
//      where it chooses what RosetteVersion is.
//      Essentially it needs to deserialize a JSON encoding of a version into
//      a datatype that Rosette can treat symbolically. 
//      Currently it takes a 4-part dictionary and returns a Rosette vector
//      This thing is something of an implementation hack, might change in the future.
//   - "versionSerialize":
//      This function should be the inverse of "versionDeserialize"
//
// Beyond these require functions, the hash map may also contain any other
// arbitrary helper functions.
// type ArbitraryFunctionsMap = HashMap<String, dsl_format::FunDef>;
type ArbitraryFunctionsMap = HashMap<String, dsl::FunDef>;


