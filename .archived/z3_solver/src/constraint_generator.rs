use crate::input_query::Dependency;
use z3::DatatypeAccessor;
use z3::DatatypeBuilder;
use z3::Symbol;
use z3::FuncDecl;
use std::collections::HashMap;
use z3::Sort;
use crate::input_query::InputQuery;
use z3::{Context, Optimize, SatResult, Model, DatatypeSort};
use z3::ast::{Ast, Bool, Datatype, Int};
use serde_json::Value;



pub struct ConstraintGenerator<'ctx> {
  context: &'ctx Context,
  optimizer: Optimize<'ctx>,
  definitions: GeneratedDefinitions<'ctx>,
  context_dep_infos: Vec<DependencyConstraintInfo<'ctx>>,
  registry_dep_infos: HashMap<String, Vec<(Value, Vec<DependencyConstraintInfo<'ctx>>)>>
}

struct GeneratedDefinitions<'ctx> {
  required_fn: FuncDecl<'ctx>,
  top_order_fn: FuncDecl<'ctx>,
  // package_sort: Sort<'ctx>,
  package_constants: HashMap<String, Datatype<'ctx>>,
  // package_testers: HashMap<String, FuncDecl<'ctx>>,
  version_dt: DatatypeSort<'ctx>,
  pv_dt: DatatypeSort<'ctx>
}

pub struct DependencyConstraintInfo<'ctx> {
  pub var: Datatype<'ctx>,
  pub dependency: Dependency,
  pub src_package_vesion: Option<(String, Value)>
}

impl GeneratedDefinitions<'_> {
  fn new<'ctx, 'a>(context: &'ctx Context, query: &'a InputQuery) -> GeneratedDefinitions<'ctx> {
    let universe = &query.universe;
    let registry = &universe.registry;

    let package_names: Vec<&String> = registry.0.keys().collect();
    let package_symbols: Vec<Symbol> = package_names.iter().map(|p| (*p).clone().into()).collect();
    let (package_sort, package_constructors_tmp, _package_testers_tmp) = Sort::enumeration(
      context,
      "Package".into(),
      &package_symbols
    );

    let package_constants: HashMap<String, Datatype> = package_names
      .iter().zip(package_constructors_tmp.iter())
      .map(|(p, ctr)| ((*p).clone(), ctr.apply(&[]).as_datatype().unwrap()))
      .collect();
    
    // let package_testers: HashMap<String, FuncDecl> = package_names
    //   .iter().zip(package_testers_tmp.into_iter())
    //   .map(|(p, tr)| ((*p).clone(), tr))
    //   .collect(); 

    let version_dt = DatatypeBuilder::new(context, "Version")
      .variant(
        "mk-version",
        vec![
          ("major", DatatypeAccessor::Sort(Sort::int(context))), 
          ("minor", DatatypeAccessor::Sort(Sort::int(context))),
          ("bug", DatatypeAccessor::Sort(Sort::int(context))),
          ("prerelease", DatatypeAccessor::Sort(Sort::int(context)))
        ])
        .finish();


    let pv_dt = DatatypeBuilder::new(context, "PV")
      .variant(
        "mk-pv",
        vec![
          ("package", DatatypeAccessor::Sort(package_sort.clone())),
          ("version", DatatypeAccessor::Sort(version_dt.sort.clone()))
        ])
        .finish();

    let required_fn = FuncDecl::new(
      context,
      "required",
      &[&pv_dt.sort],
      &Sort::bool(context));
    
    let top_order_fn = FuncDecl::new(
      context,
      "top_order",
      &[&pv_dt.sort],
      &Sort::int(context));
    

    GeneratedDefinitions {
      required_fn: required_fn,
      top_order_fn: top_order_fn,
      // package_sort: Package_sort,
      package_constants: package_constants,
      // package_testers: Package_testers,
      version_dt: version_dt,
      pv_dt: pv_dt,
    }
  }
}

impl<'ctx> ConstraintGenerator<'ctx> {
  pub fn new<'c, 'a>(context: &'c Context, query: &'a InputQuery) -> ConstraintGenerator<'c> {
    let universe = &query.universe;
    let registry = &universe.registry;

    let defs = GeneratedDefinitions::new(context, query);

    let context_dep_info: Vec<_> = universe.context_data.iter().map(|dep| {
      let var = Datatype::fresh_const(context, "edge", &defs.pv_dt.sort);
      DependencyConstraintInfo {
        var: var,
        dependency: dep.clone(),
        src_package_vesion: None
      }
    }).collect();

    // TODO: Find a way to do this with registry.map...
    let mut registry_dep_info: HashMap<String, Vec<(Value, Vec<DependencyConstraintInfo>)>> = HashMap::new();
    for (p, v, deps) in registry.iter() {
      let mut dep_infos: Vec<DependencyConstraintInfo> = Vec::new();
      for dep in deps.iter() {
        let var = Datatype::fresh_const(context, "edge", &defs.pv_dt.sort);
        let info = DependencyConstraintInfo {
          var: var,
          dependency: dep.clone(),
          src_package_vesion: Some((p.clone(), v.clone()))
        };
        dep_infos.push(info);
      }

      registry_dep_info.entry(p.clone()).or_default().push((v.clone(), dep_infos));
    }

    ConstraintGenerator { 
      context: context, 
      optimizer: Optimize::new(context),
      definitions: defs,
      context_dep_infos: context_dep_info,
      registry_dep_infos: registry_dep_info
    }
  }

  pub fn iter_deps(&self) -> impl Iterator<Item=&DependencyConstraintInfo> {
    self.context_dep_infos.iter().chain(
      self.registry_dep_infos.values()
      .flat_map(|vs| vs.iter().flat_map(|(_, deps)| deps)))
  }

  fn iter_package_versions(&self) -> impl Iterator<Item=(&String, &Value)> {
    self.registry_dep_infos.iter().flat_map(|(p, vs)| vs.iter().map(move |v| (p, &v.0)))
  }

  pub fn pv_for_package_version(&self, p_name: &String, v_json: &Value) -> Datatype<'ctx> {
    let p = self.package_for_name(p_name);
    let v = self.version_json_to_version_dt(v_json);
    self.mk_pv(p, &v)
  }

  pub fn package_for_name(&self, p_name: &String) -> &Datatype<'ctx> {
    &self.definitions.package_constants[p_name]
  }

  pub fn node_top_order(&self, node: &Option<(String, Value)>) -> Int<'ctx> {
    match node {
      None => Int::from_i64(self.context, 0),
      Some((p_name, v_json)) => self.top_order(&self.pv_for_package_version(p_name, v_json))
    }
  }

  pub fn top_order(&self, pv: &Datatype<'ctx>) -> Int<'ctx> {
    self.definitions.top_order_fn.apply(&[pv]).as_int().unwrap()
  }

  pub fn required(&self, pv: &Datatype<'ctx>) -> Bool<'ctx> {
    self.definitions.required_fn.apply(&[pv]).as_bool().unwrap()
  }

  pub fn version_matches(&self, v: &Datatype, c: &Value) -> Bool {
    // TODO: Replace this with interpretation given in DSL
    Bool::from_bool(self.context, true)
  }

  pub fn version(&self, pv: &Datatype<'ctx>) -> Datatype<'ctx> {
    self.definitions.pv_dt.variants[0].accessors[1].apply(&[pv]).as_datatype().unwrap()
  }

  pub fn package(&self, pv: &Datatype<'ctx>) -> Datatype<'ctx> {
    self.definitions.pv_dt.variants[0].accessors[0].apply(&[pv]).as_datatype().unwrap()
  }

  pub fn pv_exists(&self, pv: &Datatype<'ctx>) -> Bool<'ctx> {
    let eq_checks: Vec<_> = self.iter_package_versions().map(|(p_name, v_json)| {
      let other_pv = self.pv_for_package_version(p_name, v_json);
      pv._eq(&other_pv)
    }).collect();
    let eq_checks_ref: Vec<_> = eq_checks.iter().collect();
    
    Bool::or(self.context, &eq_checks_ref[..])
  }


  pub fn mk_pv(&self, p: &Datatype<'ctx>, v: &Datatype<'ctx>) -> Datatype<'ctx> {
    self.definitions.pv_dt.variants[0].constructor.apply(&[p, v]).as_datatype().unwrap()
  }


  pub fn version_json_to_version_dt(&self, v: &Value) -> Datatype<'ctx> {
    // TODO: Replace this with flexible semantics
    let o = v.as_object().unwrap();

    let major = Int::from_i64(self.context, o["major"].as_i64().unwrap());
    let minor = Int::from_i64(self.context, o["minor"].as_i64().unwrap());
    let bug = Int::from_i64(self.context, o["bug"].as_i64().unwrap());
    let prerelease = Int::from_i64(self.context, o["prerelease"].as_i64().unwrap());

    self.definitions.version_dt.variants[0].constructor.apply(&[&major, &minor, &bug, &prerelease]).as_datatype().unwrap()
  }

  pub fn and(&self, values: &[&Bool<'ctx>]) -> Bool {
    Bool::and(self.context, values)
  }

  pub fn and_vec(&self, values: Vec<Bool<'ctx>>) -> Bool {
    let refs: Vec<_> = values.iter().collect();
    self.and(&refs[..])
  }

  pub fn assert(&self, constraint: Bool<'ctx>) {
    self.optimizer.assert(&constraint);
  }

  pub fn check(&self) -> Result<Model, String> {
    println!("constraints:\n{:?}\n", self.optimizer);

    match self.optimizer.check(&[]) {
      SatResult::Sat => {
        let model = self.optimizer.get_model().unwrap();
        Result::Ok(model)
      },
      SatResult::Unsat => {
        println!("unsat");
        Result::Err("unsat".to_owned())
      },
      SatResult::Unknown => {        
        let reason = self.optimizer.get_reason_unknown().unwrap_or("(unknown reason)".to_owned());
        println!("unknown: {}", reason);
        Result::Err(format!("Unknown z3 result. Reason: {}", reason))
      }
    }
  }
}
