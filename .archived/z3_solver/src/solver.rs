use crate::output_format::ResolutionGraph;
use crate::input_query::InputQuery;
use crate::output_format::OutputResult;
use z3::{Context, Model};
use z3::ast::{Ast, Bool};
use crate::constraint_generator::{ConstraintGenerator, DependencyConstraintInfo};


pub struct Solver<'ctx> {
  query: InputQuery,
  generator: ConstraintGenerator<'ctx>
}

impl<'ctx> Solver<'ctx> {
  pub fn new<'c>(context: &'c Context, query: InputQuery) -> Solver<'c> {
    let gen = ConstraintGenerator::new(context, &query);
    Solver { 
      query: query, 
      generator: gen
    }
  }


  fn generate_top_order_constraint(&self, info: &DependencyConstraintInfo<'ctx>) -> Option<Bool<'ctx>> {
    if !self.query.options.check_acyclic {
      return None
    }

    let src_top_order = self.generator.node_top_order(&info.src_package_vesion);
    let dst_top_order = self.generator.top_order(&info.var);
    Some(dst_top_order.gt(&src_top_order))
  }

  fn assert_dep_constraint(&self, info: &DependencyConstraintInfo) {
    let pv_exist_constraint = self.generator.pv_exists(&info.var);
    let correct_package_constraint = self.generator.package(&info.var)
      ._eq(self.generator.package_for_name(&info.dependency.package_to_depend_on));
    let version_match_constraint = self.generator.version_matches(&self.generator.version(&info.var), &info.dependency.constraint);
    let required_constraint = self.generator.required(&info.var);
    let top_order_constraint_maybe = self.generate_top_order_constraint(info);

    let mut constraint_pieces = vec![
      pv_exist_constraint, 
      correct_package_constraint, 
      version_match_constraint, 
      required_constraint
    ];
    match top_order_constraint_maybe {
      Some(top_order_constraint) => constraint_pieces.push(top_order_constraint),
      None => ()
    }

    let conclusion = self.generator.and_vec(constraint_pieces);
    
    let final_constraint = match &info.src_package_vesion {
      Some((p_name, v_json)) => {
        let src_pv = self.generator.pv_for_package_version(p_name, v_json);
        self.generator.required(&src_pv).implies(&conclusion)
      },
      None => conclusion
    };
    
    self.generator.assert(final_constraint);
  }

  fn assert_dependency_constraints(&self) {
    for dep in self.generator.iter_deps() {
      self.assert_dep_constraint(dep)
    }
  }

  pub fn solve(&self) -> OutputResult {
    self.assert_dependency_constraints();
    let model = self.generator.check()?;
    let graph = self.model_to_graph(model);
    Ok(graph)
  }



  fn model_to_graph(&self, model: Model) -> ResolutionGraph {
    println!("model:\n{:?}", model);
    todo!()
  }
}

