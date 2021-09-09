mod input_json_format;
mod universe_traversal;


pub use input_json_format::{QueryOptions, ArbitraryFunctionsMap, Dependencies};

use input_json_format::InputQueryJSON;
use std::collections::HashMap;
use serde_json::Value;
use std::assert;

#[derive(Debug)]
pub struct InputQuery {
  // The graph of all dependencies, including registry and context
  dependency_graph: PackageUniverse<Dependencies>,
  // Some options for the query.
  options: QueryOptions,
  // The arbitrary functions given in a DSL
  functions: ArbitraryFunctionsMap,
}

#[derive(Debug)]
pub struct Registry<D>(HashMap<String, Vec<(Value, D)>>);

#[derive(Debug)]
pub struct PackageUniverse<D> {
  registry: Registry<D>,
  context_data: D,
}

impl InputQuery {
  pub fn from_path(path: &str) -> InputQuery {
    let json = InputQueryJSON::from_path(path);
    let mut reg = HashMap::new();

    for p in json.registry {
      let package = p.package;
      let versions = p.versions;
      assert!(!reg.contains_key(&package));
      let mut vers_map: Vec<(Value, Dependencies)> = Vec::new();

      for v in versions {
        let version = v.version;
        let deps = v.dependencies;
        // Value is not hashable, so we get this gross O(n^2), but whatever
        assert!(!vers_map.iter().any(|(v2, _)| version == *v2));

        vers_map.push((version, deps ));
      }

      reg.insert(package, vers_map);
    }

    let dep_graph = PackageUniverse { registry: Registry(reg), context_data: json.context_dependencies };
    InputQuery { dependency_graph: dep_graph, options: json.options, functions: json.functions }
  }
}
