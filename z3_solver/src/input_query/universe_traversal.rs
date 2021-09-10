// // use crate::input_format::*;

// use serde_json::Value;
// use std::collections::HashMap;
// use std::iter::FromIterator;
// use crate::input_query::PackageUniverse;
// use crate::input_query::Registry;


// impl<D> Registry<D> {
//   pub fn iter(&self) -> impl Iterator<Item=(&std::string::String, &serde_json::Value, &D)> + '_ {
//     self.0.iter().flat_map(|(name, versions)| versions.iter().map(move |(v, d)| (name, v, d)))
//   }

//   pub fn map<E, F>(&self, mut f: F) -> Registry<E> where F: FnMut(&String, &Value, &D) -> E, E: Clone {
//     self.iter().map(|(p, v, d)| (p, v, f(p, v, d))).collect()
//   }

//   /// Stuff
//   pub fn map_data<E, F>(&self, mut f: F) -> Registry<E> where F: FnMut(&D) -> E, E: Clone {
//     self.map(|p, v, d| f(d))
//   }
// }

// impl<D> PackageUniverse<D> where D: Clone {
//   pub fn map_data<E, F>(&self, mut f: F) -> PackageUniverse<E> where F: FnMut(&D) -> E, E: Clone {
//     let new_context = f(&self.context_data);
//     let new_reg: Registry<E> = self.registry.map_data(f);
    
//     PackageUniverse { registry: new_reg, context_data: new_context }
//   }
// }

// impl<'a, D> FromIterator<(&'a String, &'a Value, D)> for Registry<D> {
//   fn from_iter<I>(iter: I) -> Self where I: IntoIterator<Item=(&'a String, &'a Value, D)> {
//     let mut pack_reg: HashMap<String, Vec<(Value, D)>> = HashMap::new();

//     for (p, v, d) in iter {
//       let p_entry = pack_reg.entry(p.clone()).or_default();
//       p_entry.push((v.clone(), d));
//     }

//     Registry(pack_reg)
//   }
// }