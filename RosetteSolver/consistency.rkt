#lang rosette

(provide consistency/pip)
(provide consistency/npm)

(define (consistency/pip v1 v2)
  (equal? v1 v2))

(define (consistency/npm v1 v2)
  #t)
