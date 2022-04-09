open OUnit2
open Testutils

let timeout_suite : OUnit2.test =
  "timeout_suite"
  >::: [ te "istanbul-lib-instrument"
           "Timedout (timeout = 30) while running istanbul-lib-instrument.json";
         te "@jest_test-sequencer" "Timedout (timeout = 30) while running @jest_test-sequencer.json";
         te "@babel_preset-env" "Timedout (timeout = 30) while running @babel_preset-env.json";
         te "jest-config" "Timedout (timeout = 30) while running jest-config.json";
         te "jest" "Timedout (timeout = 30) while running jest.json";
         te "jest-runner" "Timedout (timeout = 30) while running jest-runner.json";
         te "copy-concurrently" "Timedout (timeout = 30) while running copy-concurrently.json";
         te "babel-plugin-istanbul" "Timedout (timeout = 30) while running babel-plugin-istanbul.json";
         te "move-concurrently" "Timedout (timeout = 30) while running move-concurrently.json";
         te "jest-jasmine2" "Timedout (timeout = 30) while running jest-jasmine2.json";
         te "node-libs-browser" "Timedout (timeout = 30) while running node-libs-browser.json";
         te "crypto-browserify" "Timedout (timeout = 30) while running crypto-browserify.json"]


let () =
  run_test_tt_main timeout_suite;

