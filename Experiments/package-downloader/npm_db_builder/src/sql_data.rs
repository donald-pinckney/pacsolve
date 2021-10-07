use std::collections::HashMap;
use rusqlite::ToSql;
use crate::sql_commands::SqlInsertable;
use chrono::Utc;
use chrono::DateTime;
use rusqlite::params;
use serde_json::Value;

#[derive(Debug)]
pub struct Package<'pkgs> {
  pub id: u64,
  pub name: &'pkgs String,
  pub downloads: Option<u64>,
  pub latest_version: Option<u64>,
  pub created: DateTime<Utc>,
  pub modified: DateTime<Utc>,
  pub other_dist_tags: Option<Value>
}

impl<'pkgs> SqlInsertable for Package<'pkgs> {
  const CREATE_SQL: &'static str = r"
    CREATE TABLE `package` (
      `id` bigint PRIMARY KEY,
      `name` varchar(255) UNIQUE NOT NULL,
      `downloads` bigint COMMENT 'Number of downloads in August 2021',
      `latest_version` bigint,
      `created` datetime NOT NULL,
      `modified` datetime NOT NULL,
      `other_dist_tags` json
    )
  ";
  const INSERT_TEMPLATE: &'static str = r"
    INSERT INTO `package` 
      (`id`, `name`, `downloads`, `latest_version`, `created`, `modified`, `other_dist_tags`) VALUES 
      (?1, ?2, ?3, ?4, ?5, ?6, ?7)
  ";
  fn params(&self) -> Vec<&dyn ToSql> { 
    // let x: i32 = 5;
    // let stuff = [&x];
    // &stuff[..]
    // let 
    vec![&self.id, self.name, &self.downloads, &self.latest_version, &self.created, &self.modified, &self.other_dist_tags]
  }
  
}

// impl<'pkgs> Package<'pkgs> {
//   fn params_tmp(&self) -> Vec<&dyn ToSql> { 
//     // let x: i32 = 5;
//     // let stuff = [&x];
//     // &stuff[..]
//     vec![&self.id, self.name]
//   }
// }

#[derive(Debug)]
pub struct Version {
  pub id: u64,
  pub package_id: u64,
  pub description: Option<String>,
  pub shasum: String,
  pub tarball: String,
  pub major: u64,
  pub minor: u64,
  pub bug: u64,
  pub prerelease: Option<String>,
  pub build: Option<String>,
  pub created: DateTime<Utc>,
  pub extra_metadata: Value
}

impl SqlInsertable for Version {
  const CREATE_SQL: &'static str = r"
    CREATE TABLE `version` (
      `id` bigint PRIMARY KEY,
      `package_id` bigint NOT NULL,
      `description` varchar(255),
      `shasum` varchar(255) NOT NULL,
      `tarball` varchar(255) NOT NULL,
      `major` bigint NOT NULL,
      `minor` bigint NOT NULL,
      `bug` bigint NOT NULL,
      `prerelease` varchar(255),
      `build` varchar(255),
      `created` datetime NOT NULL,
      `extra_metadata` json NOT NULL
    )
  ";
  const INSERT_TEMPLATE: &'static str = r"
    INSERT INTO `version` 
      (`id`, `package_id`, `description`, `shasum`, `tarball`, `major`, `minor`, `bug`, `prerelease`, `build`, `created`, `extra_metadata`) VALUES 
      (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12)
  ";
  fn params(&self) -> Vec<&dyn ToSql> { 
    vec![&self.id, &self.package_id, &self.description, &self.shasum, &self.tarball, &self.major, &self.minor, &self.bug, &self.prerelease, &self.build, &self.created, &self.extra_metadata]
  }
}

#[derive(Debug)]
pub struct Dependency {
  pub id: u64,
  pub package_raw: Option<String>,
  pub package_id: Option<u64>,
  pub spec_raw: String
}

impl SqlInsertable for Dependency {
  const CREATE_SQL: &'static str = r"
    CREATE TABLE `dependency` (
      `id` bigint PRIMARY KEY,
      `package_raw` varchar(255),
      `package_id` bigint,
      `spec_raw` varchar(255) NOT NULL
    )
  ";
  const INSERT_TEMPLATE: &'static str = r"
    INSERT INTO `dependency` 
      (`id`, `package_raw`, `package_id`, `spec_raw`) VALUES 
      (?1, ?2, ?3, ?4)
  ";
  fn params(&self) -> Vec<&dyn ToSql> { 
    vec![&self.id, &self.package_raw, &self.package_id, &self.spec_raw]
  }
}

pub const DEPENDENCY_TYPE_PROD: &'static str = "prod";
pub const DEPENDENCY_TYPE_DEV: &'static str = "dev";
pub const DEPENDENCY_TYPE_PEER: &'static str = "peer";
pub const DEPENDENCY_TYPE_OPTIONAL: &'static str = "optional";

#[derive(Debug)]
pub struct VersionDependencyRelation {
  pub version_id: u64,
  pub dependency_id: u64,
  pub dep_type: &'static str,
  pub dependency_index: u64
}

impl SqlInsertable for VersionDependencyRelation {
  const CREATE_SQL: &'static str = r"
    CREATE TABLE `version_dependencies` (
      `version_id` bigint NOT NULL,
      `dependency_id` bigint NOT NULL,
      `type` varchar(10) NOT NULL,
      `dependency_index` bigint NOT NULL,
      PRIMARY KEY (`version_id`, `dependency_id`, `type`)
    )
  ";
  const INSERT_TEMPLATE: &'static str = r"
    INSERT INTO `version_dependencies` 
      (`version_id`, `dependency_id`, `type`, `dependency_index`) VALUES 
      (?1, ?2, ?3, ?4)
  ";
  fn params(&self) -> Vec<&dyn ToSql> { 
    vec![&self.version_id, &self.dependency_id, &self.dep_type, &self.dependency_index]
  }
}

