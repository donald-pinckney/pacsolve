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
         tf "jest-jasmine2" ]

let unexpected_err_suite : OUnit2.test =
  "unexpected_err_suite"
  >::: [ te "@istanbuljs_load-nyc-config" "read-solution: unrecognized solver output: #<eof>"
           ~timeout:120;
         te "node-libs-browser" "hash-ref: no value found for key\n  key: \"lodash.upperfirst\"";
         te "crypto-browserify" "hash-ref: no value found for key\n  key: \"lodash.upperfirst\"";
         (* These last all solve, however when installing, npm crashes with this error:
                Cannot read property 'package' of null *)
         t "@babel_plugin-transform-modules-commonjs";
         t "@babel_plugin-transform-modules-amd";
         t "@jest_environment" ]

let exact_output_suite : OUnit2.test =
  "exact_output_suite"
  >::: [ t "to-width";
         t "string.prototype.split";
         t "protobufjs" ~timeout:20;
         (* These two (eslints) were reported as "unexpected" but works here (also very fast)? *)
         t "@eslint_eslintrc";
         t "eslint";
         t "@babel_plugin-transform-runtime" ~timeout:120;
         t "jest-changed-files";
         t "jest-watcher";
         t "@jest_test-result";
         t "@jest_fake-timers";
         t "nanomatch";
         t "babel-preset-jest";
         t "@babel_plugin-transform-modules-systemjs";
         t "@babel_helper-define-polyfill-provider" ~timeout:120;
         t "jest-message-util";
         t "jest-each";
         t "mississippi";
         t "babel-plugin-jest-hoist";
         t "babel-plugin-polyfill-corejs3" ~timeout:120;
         t "jest-resolve";
         t "@babel_plugin-proposal-private-methods" ]

let () =
  run_test_tt_main exact_output_suite;
  run_test_tt_main unexpected_err_suite;
  run_test_tt_main timeout_suite
