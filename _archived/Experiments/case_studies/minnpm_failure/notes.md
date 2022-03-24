# Failure Categorization


## Misc
- There is a bug if a node has a dependency with no satisfying version, PacSolve crashes. PacSolve should handle this better, but yeah not a common edge case.
  + node-libs-browser (82 seconds)
  + crypto-browserify (105 seconds)

- Z3 crash (`unrecognized solver output: #<eof>`)
  + eslint (160 seconds)
  + move-concurrently (494 seconds)
  + babel-plugin-istanbul (740 seconds)


## Timeouts (800 seconds)
- jest-config
- jest-jasmine2
- jest
- jest-runner
- copy-concurrently


## Discovery Spurious Error (succeeded locally)
- istanbul-lib-instrument
- jest-resolve
- nanomatch
- jest-message-util
- babel-preset-jest
- babel-plugin-jest-hoist
- jest-watcher
- mississippi
- babel-plugin-polyfill-corejs3
