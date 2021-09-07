use serde::Serialize;
use serde_json::{Value};
use std::fs::File;

pub type OutputResult = Result<ResolutionGraph, SolveError>;
pub type SolveError = String;

#[derive(Serialize)]
#[serde(untagged)]
enum OutputEnum {
  Success { success: bool, graph: ResolutionGraph },
  Failure { success: bool, message: String }
}

pub fn write_output_result(result: OutputResult, path: &str) {
  let oe = match result {
    Ok(g) => OutputEnum::Success { success: true, graph: g },
    Err(e) => OutputEnum::Failure { success: false, message: e }
  };
  let output_file = File::create(path).expect(&format!("Failed to open output path: {}", path));
  serde_json::to_writer(output_file, &oe).expect(&format!("Failed to write to ooutput path: {}", path));
}

#[derive(Serialize)]
pub struct ResolutionGraph {
  context_vertex: i32,
  out_edge_array: Vec<Vec<i32>>,
  vertices: Vec<Vertex>
}

#[derive(Serialize)]
enum Vertex {
  RootContextVertex,
  ResolvedPackageVertex(String, Value)
}
