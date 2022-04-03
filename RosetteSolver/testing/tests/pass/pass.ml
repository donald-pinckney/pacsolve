open OUnit2
open Testutils

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
         tp "to-width";
         tp "protobufjs" ~timeout:20;
         tp "mississippi";
         tp "jest-resolve";
         tp "@istanbuljs_load-nyc-config" ~timeout:120;
         tp "@babel_plugin-proposal-private-methods" ]

let () = run_test_tt_main pass_suite
