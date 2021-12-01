PacSolve
========

- `rosette-solver.rkt` entrypoint to the solver. The MinNPM program (written
  in JavaScript as a patch to NPM) will start this program. You can also
  launch it yourself using:

  ```
  racket rosette-solver.rkt INPUT.json OUTPUT.json
  ```

  For some example inputs, see `sample-data/`.