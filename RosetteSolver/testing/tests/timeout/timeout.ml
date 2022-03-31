open OUnit2
open Testutils

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


let () =
  run_test_tt_main timeout_suite;

