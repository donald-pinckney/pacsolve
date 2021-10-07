use rusqlite::Transaction;
use rusqlite::Connection;
use rusqlite::Params;
use std::collections::HashSet;
use rusqlite::ToSql;

pub trait SqlInsertable {
  const CREATE_SQL: &'static str;
  const INSERT_TEMPLATE: &'static str;
  fn params(&self) -> Vec<&dyn ToSql>;
}

// pub struct SqlConnection {
//   pub sqlite_conn: Connection,
// }

// impl SqlConnection {
//   pub fn new() -> SqlConnection {

//     let conn = Connection::open("npm_db.sqlite3").unwrap();

//     conn.execute_batch(r"
//       PRAGMA journal_mode = OFF;
//       PRAGMA synchronous = 0;
//       PRAGMA cache_size = 1000000;
//       PRAGMA locking_mode = EXCLUSIVE;
//       PRAGMA temp_store = MEMORY;
//     ").expect("PRAGMA");


//     SqlConnection {
//       sqlite_conn: conn
//     }
//   }

//   // pub fn transaction(&mut self) -> Transaction<'_> {
//   //   self.sqlite_conn.transaction().unwrap()
//   // }


// pub fn insert<T>(&self, data: T) where T: SqlInsertable, T: std::fmt::Debug {
//   let insert_template = T::INSERT_TEMPLATE;
//   let params = data.params();
//   self.execute_sql(insert_template, params);
// }

// fn execute_sql(&self, sql: &str, params: Vec<&dyn ToSql>) {
//   // let params_refs: Vec<&dyn ToSql> = params.iter().map(Box::as_ref).collect();
//   // if let Some(tr) = &self.transaction {
//   //   tr.execute(sql, &params[..]).expect(&format!("Failed to execute sql: {}, num_params = {}", sql, params.len()));
//   // } else {
//     self.sqlite_conn.execute(sql, &params[..]).expect(&format!("Failed to execute sql: {}, num_params = {}", sql, params.len()));
//   // }
//   // eprintln!("EXECUTING: {}, with {} params", sql, params.len());
// }