#lang racket

(provide (struct-out dep))

(provide (struct-out registry))
(provide (struct-out options))
(provide (struct-out query))

(struct dep (package constraint) #:transparent)

(struct registry (vec package-hash version-hashes) #:transparent)
(struct options (max-duplicates consistency check-acyclic min-criteria) #:transparent)
(struct query (registry context-deps options functions-hash) #:transparent)

