open OUnit2
open Testutils

let exact_output_suite : OUnit2.test =
  "exact_output_suite"
  >::: [
         t "missing-package-test-case";
         t "easy-acyclic";
         t "missing-package-test-case-acyclic";
         t "pip-consistency-sat";
         t "pip-consistency-sat2";
  ]

let () =
  run_test_tt_main exact_output_suite;

