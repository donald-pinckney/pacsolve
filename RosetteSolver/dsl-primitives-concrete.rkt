#lang racket

(provide DSL-PRIMITIVES-CONCRETE)

(define (make-json-hash assocs)
  (make-hasheq (map (lambda (p) (cons (string->symbol (car p)) (cdr p))) assocs)))

;; Loaded for functions: "versionDeserialize", "versionSerialize", "consistency"
(define DSL-PRIMITIVES-CONCRETE (make-immutable-hash (list
  (cons "immutable-vector" vector-immutable)
  (cons "cons" cons)
  (cons "list" list)
  (cons "make-json-hash" make-json-hash)
)))