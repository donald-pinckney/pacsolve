# Playing around with modeling dependency resolution with solvers

## Current sketches of models

1. `model-no-duplicates-yes-cycles.smt2`: This models a dependency resolution graph that disallows duplicate vertices, but does allow solutions to contain cycles. To run, install [Z3 command line binary](https://github.com/Z3Prover/z3), then run `z3 model-no-duplicates-yes-cycles.smt2`
  - Pro: Cycles are representable
  - Pro: Quantifier free, and seems like it would be promising to implement in Python as a reasonable algorithm
  - Con: Can't represent solves in which we have duplicate package@version vertices. Unsure if this matters for the paper, but at least is relevant for Spack.
  - Unknown: Don't yet see a way to easily constrain to non-cyclic graphs, without creating a whole new model. ~~Perhaps [Z3 fixedpoints](https://rise4fun.com/Z3/tutorial/fixedpoints) would be usable?~~ **EDIT: Z3 fixedpoints don't seem to let you interact with SMT at all.**
  - Unknown: Haven't yet thought about how optimization would be done in this model

2. `model-yes-duplicates-yes-cycles.smt2`: This models a dependency resolution graph that does allow duplicate vertices, as well as cycles. To run, install [Z3 command line binary](https://github.com/Z3Prover/z3), then run `z3 model-yes-duplicates-yes-cycles.smt2`
  - Pro: Cycles are representable
  - Pro: Duplicate vertices are representable
  - Con: Contains universal quantifiers, which seemingly do not mix well with optimization. Easily starts giving "unknown" or timeouts for the smallest examples. Seems impractical for implementation
  - Con: It would seem that [Z3 fixedpoints](https://rise4fun.com/Z3/tutorial/fixedpoints) **can not** be used to detect cycles in this model, due to the restriction of disallowing uninterpreted functions (thus Arrays) in the left hand size of a `rule` clause.

3. `rosette-solver.rkt`: This implements a dependnecy graph solver using [Rosette](https://emina.github.io/rosette/). To run, [install Rosette](https://github.com/emina/rosette#installing-rosette), open `rosette-solver.rkt` in DrRacket, and hit run.
  - Cycles are representable, 
  - Optional assertion to constraint to a DAG is implemented.
  - Duplicate nodes are representable, under an adjustable bound.
  - Graph consistency relation constraints are implemented.
  - Optimization criteria are implemented (currently minimizing # of nodes)
  - Quantifier free
  - Unknown: does this perform at scale?
