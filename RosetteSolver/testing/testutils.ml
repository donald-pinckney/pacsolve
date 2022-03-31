open OUnit2
open Runner


let def_TIMEOUT = 30

(* To run a test with an exact expected output *)
let t ?(timeout = def_TIMEOUT) (name : string) : OUnit2.test = name >:: test_run name timeout

(* To run a test with an exact expected outputted error*)
let te ?(timeout = def_TIMEOUT) (name : string) (error_msg : string) : OUnit2.test =
  name >:: test_run_error name error_msg timeout

(* To run a test and expect the program to succeed *)
let tp ?(timeout = def_TIMEOUT) (name : string) : OUnit2.test =
  name >:: test_run_pass_fail name timeout TestPass

(* To run a test and expect the program to fail *)
let tf ?(timeout = def_TIMEOUT) (name : string) : OUnit2.test =
  name >:: test_run_pass_fail name timeout TestFail

