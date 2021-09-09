use crate::input_query::InputQuery;
use crate::output_format::OutputResult;
use z3::{Config, Context, Optimize};
use z3::ast::*;


pub struct Solver<'ctx> {
  query: InputQuery,
  context: &'ctx Context,
  optimizer: Optimize<'ctx>
}

impl Solver<'_> {
  pub fn new<'ctx>(context: &'ctx Context, query: InputQuery) -> Solver<'ctx> {
    Solver { query: query, context: context, optimizer: Optimize::new(context) }
  }


  pub fn solve(self) -> OutputResult {
    let t = Bool::from_bool(self.context, true);
    self.optimizer.assert(&t);


    Result::Err("bad".to_owned())
  }
}