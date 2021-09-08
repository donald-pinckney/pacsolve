mod input_json_format;


pub use input_json_format::{QueryOptions, ArbitraryFunctionsMap, Dependencies};

use input_json_format::InputQueryJSON;
use std::collections::HashMap;
use serde_json::Value;
use std::assert;

#[derive(Debug)]
pub struct InputQuery {
  // The graph of all dependencies, including registry and context
  dependency_graph: DependencyGraph,
  // Some options for the query.
  options: QueryOptions,
  // The arbitrary functions given in a DSL
  functions: ArbitraryFunctionsMap,
}

#[derive(Debug)]
pub struct DependencyGraph {
  registry: HashMap<String, Vec<(Value, PackageVersionData)>>,
  context_dependencies: Dependencies,
}

#[derive(Debug)]
struct PackageVersionData {
  dependencies: Dependencies
}

impl InputQuery {
  pub fn from_path(path: &str) -> InputQuery {
    let json = InputQueryJSON::from_path(path);
    let mut reg = HashMap::new();

    for p in json.registry {
      let package = p.package;
      let versions = p.versions;
      assert!(!reg.contains_key(&package));
      let mut vers_map: Vec<(Value, PackageVersionData)> = Vec::new();

      for v in versions {
        let version = v.version;
        let deps = v.dependencies;
        // Value is not hashable, so we get this gross O(n^2), but whatever
        assert!(!vers_map.iter().any(|(v2, _)| version == *v2));

        vers_map.push((version, PackageVersionData { dependencies: deps }));
      }

      reg.insert(package, vers_map);
    }

    let dep_graph = DependencyGraph { registry: reg, context_dependencies: json.context_dependencies };
    InputQuery { dependency_graph: dep_graph, options: json.options, functions: json.functions }
  }
}
