#lang racket

(require "function-dsl.rkt")
(require "dsl-primitives-concrete.rkt")

(provide (struct-out dep))

(provide (struct-out parsed-package))
(provide (struct-out parsed-package-version))
(provide (struct-out registry))
(provide (struct-out min-objective))
(provide (struct-out options))
(provide (struct-out query))

(provide serialize-version)
(provide evaluate-consistency)

(struct dep (package constraint) #:transparent)

(struct parsed-package-version (version cost-values dep-vec) #:transparent)
(struct parsed-package (package cost-values pv-vec) #:transparent)
(struct registry (vec package-hash version-hashes) #:transparent)
(struct min-objective (vertex_cost_key package_cost_key version_group_combiner_name packages_combiner_name) #:transparent)
(struct options (max-duplicates check-acyclic min-objectives-names) #:transparent)
(struct query (registry context-deps options functions-hash) #:transparent)


(define (serialize-version query version)
  (eval-dsl-function
    DSL-PRIMITIVES-CONCRETE
    (query-functions-hash query)
    "versionSerialize"
    (list version)))

(define (evaluate-consistency query v1 v2)
  (eval-dsl-function
    DSL-PRIMITIVES-CONCRETE
    (query-functions-hash query)
    "consistency"
    (list v1 v2)))