#lang rosette

; (display (current-bitwidth))

(provide DSL-PRIMITIVES-SYMBOLIC)

(define (make-json-hash assocs)
  (make-hasheq (map (lambda (p) (cons (string->symbol (car p)) (cdr p))) assocs)))

;; Loaded for functions: "constraintInterpretation"
(define DSL-PRIMITIVES-SYMBOLIC (make-immutable-hash (list
  (cons "make-json-hash" make-json-hash) ;; might be wrong
  (cons "list" list)
  (cons "cons" cons)
  (cons "&&" &&)
  (cons "||" ||)
  (cons "apply" (lambda (f x) (f x)))
  (cons "not" not)
  (cons "vector-ref" vector-ref)
  (cons "<" <)
  (cons "==" =)
  (cons ">" >)
)))