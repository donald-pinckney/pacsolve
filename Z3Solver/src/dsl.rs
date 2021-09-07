use std::collections::HashMap;
use serde::Deserialize;

#[derive(Deserialize, Debug)]
#[serde(untagged)]
enum Value {
  Int(i32),
  Bool(bool),
  String(String),
  Dictionary(HashMap<String, Value>),
  Tuple(Vec<Value>)
}

#[derive(Deserialize, Debug)]
enum Expr {
  #[serde(rename_all = "camelCase", rename = "VarExpr")]
  Var { var_name: String },
  #[serde(rename = "ConstExpr")]
  Const { value: Value },
  #[serde(rename_all = "camelCase", rename = "LetExpr")]
  Let { var_name: String, bind_value: Box<Expr>, rest: Box<Expr> },
  #[serde(rename = "PrimitiveOpExpr")]
  PrimitiveOp { op: String, args: Vec<Expr> },
  #[serde(rename = "LambdaExpr")]
  Lambda { param: String, body: Box<Expr> },
  #[serde(rename_all = "camelCase", rename = "CallExpr")]
  Call { name: String, args: Vec<Expr> }
}

#[derive(Deserialize, Debug)]
enum Pattern {
  WildcardPattern {},
  ConstPattern { value: Value },
  BindingPattern { name: String },
  #[serde(rename_all = "camelCase", rename = "DictionaryPattern")]
  Dictionary { names_patterns_dict: HashMap<String, Pattern> },
  VectorPattern { patterns: Vec<Pattern> }
}

#[derive(Deserialize, Debug)]
struct FunctionRule {
  patterns: Vec<Pattern>,
  rhs: Expr
}

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
pub struct FunDef {
  num_params: i32,
  rules: Vec<FunctionRule>
}
