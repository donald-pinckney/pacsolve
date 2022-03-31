open OUnit2
open Testutils

let unexpected_err_suite : OUnit2.test =
  "unexpected_err_suite"
  >::: [ te "@istanbuljs_load-nyc-config" "read-solution: unrecognized solver output: #<eof>"
           ~timeout:120 ]

let () = run_test_tt_main unexpected_err_suite
