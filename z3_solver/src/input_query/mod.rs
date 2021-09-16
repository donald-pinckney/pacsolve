mod input_json_format;
mod universe_traversal;


pub use input_json_format::{QueryOptions, ArbitraryFunctionsMap, Dependencies, Dependency};
pub use universe_traversal::*;

use input_json_format::InputQueryJSON;
use std::collections::HashMap;
use serde_json::Value;
use std::assert;
use std::iter::FromIterator;


#[derive(Debug)]
pub struct InputQuery {
  // The graph of all dependencies, including registry and context
  pub universe: PackageUniverse<Dependencies>,
  // Some options for the query.
  pub options: QueryOptions,
  // The arbitrary functions given in a DSL
  functions: ArbitraryFunctionsMap,
}

#[derive(Debug)]
pub struct Registry<D>(pub HashMap<String, Vec<(Value, D)>>);

#[derive(Debug)]
pub struct PackageUniverse<D> {
  pub registry: Registry<D>,
  pub context_data: D,
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
    InputQuery { universe: dep_graph, options: json.options, functions: json.functions }
  }
}



impl<D> PackageUniverse<D> where D: Clone {
  pub fn map_data<E, F>(&self, mut f: F) -> PackageUniverse<E> where F: FnMut(&D) -> E, E: Clone {
    let new_context = f(&self.context_data);
    let new_reg: Registry<E> = self.registry.map_data(f);
    
    PackageUniverse { registry: new_reg, context_data: new_context }
  }
}

impl<D> Registry<D> {
  pub fn new() -> Registry<D> {
    Registry(HashMap::new())
  }

  pub fn insert(&mut self, p: String, v: Value, d: D) {
    self.0.entry(p).or_default().push((v, d));
  }

  pub fn iter(&self) -> impl Iterator<Item=(&std::string::String, &serde_json::Value, &D)> + '_ {
    self.0.iter().flat_map(|(name, versions)| versions.iter().map(move |(v, d)| (name, v, d)))
  }

  pub fn map<E, F>(&self, mut f: F) -> Registry<E> where F: FnMut(&String, &Value, &D) -> E, E: Clone {
    self.iter().map(|(p, v, d)| (p, v, f(p, v, d))).collect()
  }

  pub fn map_data<E, F>(&self, mut f: F) -> Registry<E> where F: FnMut(&D) -> E, E: Clone {
    self.map(|p, v, d| f(d))
  }
}

impl<'a, D> FromIterator<(&'a String, &'a Value, D)> for Registry<D> {
  fn from_iter<I>(iter: I) -> Self where I: IntoIterator<Item=(&'a String, &'a Value, D)> {
    let mut pack_reg: HashMap<String, Vec<(Value, D)>> = HashMap::new();

    for (p, v, d) in iter {
      let p_entry = pack_reg.entry(p.clone()).or_default();
      p_entry.push((v.clone(), d));
    }

    Registry(pack_reg)
  }
}