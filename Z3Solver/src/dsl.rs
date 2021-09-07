use std::collections::HashMap;

enum Value {
  Int(i32),
  Bool(bool),
  String(String),
  Dictionary(HashMap<String, Value>),
  Vector(Vec<Value>)
  // ... probably some other things need to go here...
}

enum Expr {
  Var(String),
  Const(Value),
  Let(String, Box<Expr>, Box<Expr>),
  PrimitiveOp(String, Vec<Expr>),
  Lambda(String, Box<Expr>),
  Call(String, Vec<Expr>)
}


enum Pattern {
  Wildcard,
  Const(Value),
  Binding(String),
  Dictionary(HashMap<String, Pattern>),
  Vector(Vec<Pattern>)
}


struct FunctionRule {
  patterns: Vec<Pattern>,
  rhs: Expr
}

pub struct FunDef {
  num_params: i32,
  rules: Vec<FunctionRule>
}
