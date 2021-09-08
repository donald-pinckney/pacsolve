use std::fs::File;
use serde::Deserialize;
use serde_json::Value;
use std::collections::HashMap;
use crate::dsl;


#[derive(Deserialize, Debug)]
pub struct InputQueryJSON {
  // A listing of all relevant named packages & versions & dependencies
  pub registry: Vec<PackageJSON>, 
  // The dependencies of the "context" node, that is, the dependencies
  // of the place we are running `npm install` from.
  pub context_dependencies: Dependencies,
  // Some options for the query.
  pub options: QueryOptions,
  // The arbitrary functions given in a DSL
  pub functions: ArbitraryFunctionsMap,
}

impl InputQueryJSON {
  pub fn from_path(path: &str) -> InputQueryJSON {
    let input_file = File::open(path).expect(&format!("Failed to open input path: {}", path));
    serde_json::from_reader(input_file).expect("Failed to parse input JSON")
  }
}

#[derive(Deserialize, Debug)]
pub struct PackageJSON {
  // The name of the package
  pub package: String,
  // List of all the specific versions of a package
  pub versions: Vec<VersionOfAPackageJSON>
}

#[derive(Deserialize, Debug)]
pub struct VersionOfAPackageJSON {
  // An arbitrary JSON blob encoding the version number, 
  // but it must be deserializable by the
  // "versionDeserialize" function (see below) 
  pub version: Value, // This has "type" JsonVersion

  // The dependencies of this version of the package
  pub dependencies: Dependencies
}

pub type Dependencies = Vec<Dependency>;

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct Dependency {
  // The name of the package to depend on,
  // refers to `package_name` field in `Package`.
  package_to_depend_on: String,

  // An arbitrary JSON blob encoding the version constraint of the dependency.
  // It must be readable by the "constraintInterpretation" function (see below).
  constraint: Value // This has "type" JsonConstraint
}

#[derive(Deserialize, Debug)]
pub struct QueryOptions {
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
pub type ArbitraryFunctionsMap = HashMap<String, dsl::FunDef>;


