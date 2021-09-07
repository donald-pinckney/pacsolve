mod input_format;
mod output_format;
mod dsl;
mod solver;

use std::env;
use input_format::InputQuery;
use output_format::write_output_result;
use solver::Solver;


fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() != 3 {
        panic!("Usage: Z3Solver <input JSON> <output JSON>")
    }

    let input_path = &args[1];
    let output_path = &args[2];

    let input = InputQuery::from_path(input_path);
    println!("{:?}", input);
    let solver = Solver::new(input);
    let output = solver.solve();
    write_output_result(output, output_path);
}
