#lang rosette

(require "graph.rkt")
(require "query.rkt")
(require "query-access.rkt")

;;; -------------------------------------------
;;; SYMBOLIC GRAPH GENERATION (SKETCHING)
;;; -------------------------------------------

(provide graph*)

; fin* generates a symbolic integer x such that 0 <= x < n

;; TODO: Explore an alternative encoding.
;; This encoding generates (n-1) booleans
;; Instead we could generate a single
;; integer / bitvector, and put an upper bound
;; assertion on it
(define (fin* n)
  (if
   (= n 1)
   (bv 0 (bitvector 1))
   (begin
     (define num-bits (integer-length (- n 1)))
     (define bv-n (bv (- n 1) (bitvector num-bits)))
     (define-symbolic* x (bitvector num-bits))
     (assert (bvule x bv-n))
     x)))

; (apply choose* (range n))) ;; TODO: play with representation


(define (edge* query p-idx)
  (edge
   p-idx
   (fin* (registry-num-versions query p-idx))))

(define (node* query deps)
  (define-symbolic* active boolean?) ;; TODO: play with representation
  (define-symbolic* ts integer?) ;; TODO: play with representation
  (node
   active
   (map
    (lambda (dep)
      (match (package-index query (dep-package dep))
        [-1 (void)]
        [pkg-idx (edge* query pkg-idx)]
        ))
    deps)
   ts))

(define (version-node* query version cost-values deps)
  (version-node
   version
   cost-values
   (node* query deps)))

(define (package-group* query package)
  (define p-idx (package-index query package))
  (define version-idxs (range (registry-num-versions query p-idx)))
  (define cost-values (registry-package-cost-values query p-idx))

  (define version-nodes
    (map
     (lambda (version-idx)
       (define parsed-pv (registry-ref query p-idx version-idx))
       (version-node*
        query
        (parsed-package-version-version parsed-pv)
        (parsed-package-version-cost-values parsed-pv)
        (parsed-package-version-dep-vec parsed-pv)))
     version-idxs))

  (package-group
   package
   cost-values
   (vector->immutable-vector (list->vector version-nodes))))

;; graph* : Query -> Graph
(define (graph* query)
  (define context-node (node* query (context-deps query)))
  (define p-idxs (range (registry-num-packages query)))
  (define package-groups
    (map
     (lambda (p-idx)
       (package-group* query (registry-package-name query p-idx)))
     p-idxs))

  (graph context-node package-groups))
