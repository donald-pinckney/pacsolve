use crate::input_query::Registry;
use crate::output_format::ResolutionGraph;
use crate::input_query::InputQuery;
use crate::output_format::OutputResult;
use z3::{Config, Context, Optimize, SatResult, Model};
use z3::ast::Bool;


pub struct Solver<'ctx> {
  query: InputQuery,
  context: &'ctx Context,
  optimizer: Optimize<'ctx>
}

impl Solver<'_> {
  pub fn new<'ctx>(context: &'ctx Context, query: InputQuery) -> Solver<'ctx> {
    Solver { query: query, context: context, optimizer: Optimize::new(context) }
  }

  fn model_to_graph(&self, model: Model) -> ResolutionGraph {
    println!("model:\n{:?}", model);
    todo!()
  }


  pub fn solve(&self) -> OutputResult {
    let universe = &self.query.universe;
    let registry = &universe.registry;

    let vars_enabled: Registry<Bool> = registry.map(|p, v, n| Bool::fresh_const(self.context, "enabled"));

    vars_enabled.map_data(|b| self.optimizer.assert(b));

    println!("{:?}", self.optimizer);    
    
    match self.optimizer.check(&vec![]) {
      SatResult::Sat => {
        let model = self.optimizer.get_model().unwrap();
        let graph = self.model_to_graph(model);
        Result::Ok(graph)
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