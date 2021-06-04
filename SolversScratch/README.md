# Playing around with modeling dependency resolution with solvers

1. Install [Z3 command line binary](https://github.com/Z3Prover/z3)
2. Run `z3 [some_file].smt2`

## Current sketches of models

1. `model-no-duplicates-yes-cycles.smt2`: This models a dependency resolution graph that disallows duplicate vertices, but does allow solutions to contain cycles.
  - Pro: Cycles are representable
  - Pro: Quantifier free, and seems like it would be promising to implement in Python as a reasonable algorithm
  - Con: Can't represent solves in which we have duplicate package@version vertices. Unsure if this matters for the paper, but at least is relevant for Spack.
  - Unknown: Don't yet see a way to easily constrain to non-cyclic graphs, without creating a whole new model. Perhaps [Z3 fixedpoints](https://rise4fun.com/Z3/tutorial/fixedpoints) would be usable?
  - Unknown: Haven't yet thought about how optimization would be done in this model

2. `model-yes-duplicates-yes-cycles.smt2`: This models a dependency resolution graph that does allow duplicate vertices, as well as cycles.
  - Pro: Cycles are representable
  - Pro: Duplicate vertices are representable
  - Con: Contains universal quantifiers, which seemingly do not mix well with optimization. Easily starts giving "unknown" or timeouts for the smallest examples. Seems impractical for implementation
  - Con: It would seem that [Z3 fixedpoints](https://rise4fun.com/Z3/tutorial/fixedpoints) **can not** be used to detect cycles in this model, due to the restriction of disallowing uninterpreted functions (thus Arrays) in the left hand size of a `rule` clause.
