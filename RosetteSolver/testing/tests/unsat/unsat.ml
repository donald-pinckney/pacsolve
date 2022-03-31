open OUnit2
open Testutils

let unsat_err_suite : OUnit2.test =
  "unsat_err_suite" >::: [te "missing-package-test-case-unsat" "Failed to solve constraints :("]

let () = run_test_tt_main unsat_err_suite
