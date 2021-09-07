use crate::input_format::InputQuery;
use crate::output_format::OutputResult;


pub struct Solver {
  query: InputQuery
}

impl Solver {
  pub fn new(q: InputQuery) -> Solver {
    Solver { query: q }
  }

  pub fn solve(self) -> OutputResult {
    Result::Err("bad".to_owned())
  }
}