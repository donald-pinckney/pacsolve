open OUnit2
open Runner

let tfile (name : string) : OUnit2.test = name >:: test_run name

let exact_output_suite : OUnit2.test = "exact_output_suite" >::: [tfile "to-width"]

let () = run_test_tt_main exact_output_suite
