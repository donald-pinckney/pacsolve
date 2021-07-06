#lang rosette

(require rosette/lib/angelic)
(require "graph.rkt")
(require "query.rkt")
(require "query-access.rkt")

;;; -------------------------------------------
;;; SYMBOLIC GRAPH GENERATION (SKETCHING)
;;; -------------------------------------------

(provide graph*)

; A different version of the bounded recursion macro from:
; https://docs.racket-lang.org/rosette-guide/ch_essentials.html?q=constant#%28part._sec~3anotes%29
(define-syntax-rule
  (define-bounded (id param ...) body ...)
  (define id
    (local
      [(define fuel (make-parameter 0)) ; tmp value
       (define (id param ...)
         (assert (>= (fuel) 0) "Out of fuel.")
         (parameterize ([fuel (sub1 (fuel))])
           body ...))]
      (lambda (max-fuel param ...)
        (parameterize ([fuel max-fuel])
          (id param ...))))))


(define-bounded (range-s n)
  (if (> n 0)
      (cons (- n 1) (range-s (- n 1)))
      '()))


(define (range-s-not-bound n)
  (if (> n 0)
      (cons (- n 1) (range-s-not-bound (- n 1)))
      '()))

(define (fin* n)
  (apply choose* (range n)))

(define (build-list-s* bound len-s f)
  (map (lambda (_) (f)) (range-s bound len-s)))

(define (edge* p-idx max-duplicates)
  (edge
   p-idx
   (fin* (registry-num-versions p-idx))
   (fin* max-duplicates)))

(define (node* deps max-duplicates)
  (define-symbolic* ts integer?)
  (node
   (map
    (lambda (dep) (edge* (package-index (dep-package dep)) max-duplicates))
    deps)
   ts))

(define (version-group* version deps max-duplicates)
  (define num-nodes (fin* (add1 max-duplicates)))
  (define nodes
    (build-list-s* max-duplicates num-nodes (lambda () (node* deps max-duplicates))))
  (version-group version num-nodes nodes))

(define (package-group* package max-duplicates)
  (define p-idx (package-index package))
  (define version-idxs (range (registry-num-versions p-idx)))
  
  (define version-groups
    (map
     (lambda (version-idx)
       (define version-pair (registry-ref p-idx version-idx))
       (version-group* (car version-pair) (cdr version-pair) max-duplicates))
     version-idxs))

  (package-group package (vector->immutable-vector (list->vector version-groups))))

(define (graph* max-duplicates)
  (define context-node (node* CONTEXT-DEPS max-duplicates))
  (define p-idxs (range REGISTRY-NUM-PACKAGES))
  (define package-groups
    (map
     (lambda (p-idx) (package-group* (registry-package-name p-idx) max-duplicates))
     p-idxs))
 
  (graph context-node package-groups))
