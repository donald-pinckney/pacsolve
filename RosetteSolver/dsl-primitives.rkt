#lang rosette

(provide DSL-PRIMITIVES)

(define (make-json-hash assocs)
  (make-hash (map (lambda (p) (cons (string->symbol (car p)) (cdr p))) assocs)))

(define DSL-PRIMITIVES (make-immutable-hash (list
  (cons "immutable-vector" vector-immutable)
  (cons "equal?" equal?)
  (cons "cons" cons)
  (cons "list" list)
  (cons "make-json-hash" make-json-hash)
)))