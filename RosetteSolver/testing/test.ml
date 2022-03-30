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

let timeout_suite : OUnit2.test =
  "timeout_suite"
  >::: [ te "istanbul-lib-instrument"
           "Timedout (timeout = 30) while running istanbul-lib-instrument.json";
         te "@jest_test-sequencer" "Timedout (timeout = 30) while running @jest_test-sequencer.json";
         tf "@babel_preset-env";
         tf "jest-config";
         tf "jest";
         tf "jest-runner";
         tf "copy-concurrently";
         tf "babel-plugin-istanbul";
         tf "move-concurrently";
         tf "jest-jasmine2";
         tf "node-libs-browser";
         tf "crypto-browserify" ]

let unsat_err_suite : OUnit2.test =
  "unsat_err_suite" >::: [te "missing-package-test-case-unsat" "Failed to solve constraints :("]

let unexpected_err_suite : OUnit2.test =
  "unexpected_err_suite"
  >::: [ te "@istanbuljs_load-nyc-config" "read-solution: unrecognized solver output: #<eof>"
           ~timeout:120 ]

let pass_suite : OUnit2.test =
  "pass_suite"
  >::: [ tp "string.prototype.split";
         (* These two (eslints) were reported as "unexpected" but works here (also very fast)? *)
         tp "@eslint_eslintrc";
         tp "eslint";
         tp "@babel_plugin-transform-runtime" ~timeout:120;
         tp "jest-changed-files";
         tp "jest-watcher";
         tp "@jest_test-result";
         tp "@jest_fake-timers";
         tp "nanomatch";
         tp "babel-preset-jest";
         tp "@babel_plugin-transform-modules-systemjs";
         tp "@babel_helper-define-polyfill-provider" ~timeout:120;
         tp "jest-message-util";
         tp "@babel_plugin-transform-modules-commonjs";
         tp "@jest_environment";
         tp "@babel_plugin-transform-modules-amd";
         tp "babel-plugin-polyfill-corejs3" ~timeout:120;
         tp "babel-plugin-jest-hoist";
         tp "jest-each";
         tp "jest-resolve";
         tp "@babel_plugin-proposal-private-methods" ]

let exact_output_suite : OUnit2.test =
  "exact_output_suite"
  >::: [ t "to-width";
         t "protobufjs" ~timeout:20;
         t "missing-package-test-case";
         t "mississippi" ]

let () =
  run_test_tt_main exact_output_suite;
  run_test_tt_main unexpected_err_suite;
  run_test_tt_main timeout_suite;
  run_test_tt_main pass_suite;
  run_test_tt_main unsat_err_suite
