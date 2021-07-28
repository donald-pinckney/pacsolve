#lang racket

(require "function-dsl.rkt")
(require "dsl-primitives-concrete.rkt")

(provide (struct-out dep))

(provide (struct-out registry))
(provide (struct-out options))
(provide (struct-out query))

(provide serialize-version)
(provide evaluate-consistency)

(struct dep (package constraint) #:transparent)

(struct registry (vec package-hash version-hashes) #:transparent)
(struct options (max-duplicates consistency check-acyclic min-criteria) #:transparent)
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