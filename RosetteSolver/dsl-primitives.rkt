#lang rosette

(provide DSL-PRIMITIVES)

(define DSL-PRIMITIVES (make-immutable-hash (list
  (cons "immutable-vector" vector-immutable)
  (cons "equal?" equal?)
  (cons "cons" cons)
  (cons "make-json-hash" make-hash)
)))