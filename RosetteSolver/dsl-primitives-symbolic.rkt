#lang rosette

(provide DSL-PRIMITIVES-SYMBOLIC)

(define DSL-PRIMITIVES-SYMBOLIC (make-immutable-hash (list
  (cons "equal?" equal?)
  (cons "immutable-vector" vector-immutable)
  (cons "&&" &&)
  (cons "||" ||)
  (cons "=" =)
  (cons ">=" >=)
  (cons ">" >)
  (cons "vector-ref" vector-ref)
)))