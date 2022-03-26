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

let exact_output_suite : OUnit2.test =
  "exact_output_suite"
  >::: [ t "to-width";
         t "string.prototype.split";
         t "protobufjs" ~timeout:20;
         te "istanbul-lib-instrument"
           "Timedout (timeout = 30) while running istanbul-lib-instrument.json";
         (* This one takes way too long *)
         te "@jest_test-sequencer" "Timedout (timeout = 30) while running @jest_test-sequencer.json";
         (* These two (eslints) were reported as "unexpected" but works here? *)
         t "@eslint_eslintrc";
         t "eslint";
         t "@babel_plugin-transform-runtime" ~timeout:120;
         t "jest-changed-files";
         (* On this one racket crashes... *)
         te "@istanbuljs_load-nyc-config" "read-solution: unrecognized solver output: #<eof>"
           ~timeout:120;
         te "node-libs-browser" "hash-ref: no value found for key\n  key: \"lodash.upperfirst\"";
         te "crypto-browserify" "hash-ref: no value found for key\n  key: \"lodash.upperfirst\"" ]

let () = run_test_tt_main exact_output_suite
