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

(define (edge* query p-idx)
  (edge
   p-idx
   (fin* (registry-num-versions query p-idx))
   (fin* (options-max-duplicates (query-options query)))))

(define (node* query deps)
  (define-symbolic* ts integer?)
  (node
   (map
    (lambda (dep) (edge* query (package-index query (dep-package dep))))
    deps)
   ts))

(define (version-group* query version deps)
  (define num-nodes (fin* (add1 (options-max-duplicates (query-options query)))))
  (define nodes
    (build-list-s* (options-max-duplicates (query-options query)) num-nodes (lambda () (node* query deps))))
  (version-group version num-nodes nodes))

(define (package-group* query package)
  (define p-idx (package-index query package))
  (define version-idxs (range (registry-num-versions query p-idx)))
  
  (define version-groups
    (map
     (lambda (version-idx)
       (define version-pair (registry-ref query p-idx version-idx))
       (version-group* query (car version-pair) (cdr version-pair)))
     version-idxs))

  (package-group package (vector->immutable-vector (list->vector version-groups))))

(define (graph* query)
  (define context-node (node* query (context-deps query)))
  (define p-idxs (range (registry-num-packages query)))
  (define package-groups
    (map
     (lambda (p-idx) (package-group* query (registry-package-name query p-idx)))
     p-idxs))
 
  (graph context-node package-groups))
