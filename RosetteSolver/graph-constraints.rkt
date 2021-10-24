#lang rosette

(require "graph.rkt")
(require "query.rkt")
(require "query-access.rkt")

(provide check-graph)

;;; -------------------------------------------
;;; CONSTRAINT GENERATION
;;; -------------------------------------------



;;; *** Constraints part 1: Checking that the graph is a DAG. 
;;; This check can simply be omitted to allow cyclic graphs
(define (check-graph-acyclic query g)
  (assert (= 0 (node-top-order (graph-context-node g))))
  (for/graph-edges query g
    (lambda (e c _sp _sv src-node)
      (define dp-idx (edge-package-idx e)) ; not symbolic
      (define dv-idx (edge-version-idx e)) ; symbolic

      (define dp-group (list-ref (graph-package-groups-list g) dp-idx))
      (define dv-node (vector-ref (package-group-version-nodes-vec dp-group) dv-idx))
      
      (assert (< (node-top-order src-node) (node-top-order (version-node dv-node)))))))
                                             
  

;;; *** Constraints part 2: Checking that the graph satisfies all dependency constraints
(define (sat/version-constraint v-s c)
  (c v-s))

(define (check-graph-sat-deps query g)
  (assert (node-active (graph-context-node g)))
  (for/graph-edges query g (lambda (e constraint _p _v src-node)
    (if (node-active src-node)
      (begin
        (define dp-idx (edge-package-idx e)) ; not symbolic
        (define dv-idx (edge-version-idx e)) ; symbolic

        (define dp-group (list-ref (graph-package-groups-list g) dp-idx))
        (define dv-node (vector-ref (package-group-version-nodes-vec dp-group) dv-idx))

        (define dest-version (version-node-version dv-node))

        (assert (node-active (version-node-node dv-node)))
        (assert (sat/version-constraint dest-version constraint))
      )
      #t))))


;;; *** Constraints part 3: Checking that the graph contains pairwise consistent versions of the same package, parameterized by relation `r`
(define (check-graph-consistent query g r)
  (for-each
   (lambda (p-idx)
     (define n-vers (registry-num-versions query p-idx))
     (define p-group (list-ref (graph-package-groups-list g) p-idx)) ; the package group in the graph
     
     (for-each
      (lambda (v1-idx)
        (define v1 (car (registry-ref query p-idx v1-idx)))
        (define v1-version-node (vector-ref (package-group-version-nodes-vec p-group) v1-idx)) ; the version node for v1
        (define v1-active (node-active (version-node-node v1-version-node)))
        
        (for-each
         (lambda (v2-idx)
           (define v2 (car (registry-ref query p-idx v2-idx)))
           (define v2-version-node (vector-ref (package-group-version-nodes-vec p-group) v2-idx)) ; the version node for v2
           (define v2-active (node-active (version-node-node v2-version-node)))

           (if (not (r v1 v2)) ; v1 and v2 are concrete
               (assert (not (and v1-active v2-active))) ; v1-active and v2-active are symbolic
               #t))
         (range v1-idx)))
      (range n-vers)))
   (range (registry-num-packages query))))

;;; *** Final constraint generation
(define (check-graph query g)
  (define (consistency-rel v1 v2) (evaluate-consistency query v1 v2))
  (define check-acyclic (options-check-acyclic (query-options query)))

  (check-graph-sat-deps query g)
  (if check-acyclic (check-graph-acyclic query g) #t)
  (check-graph-consistent query g consistency-rel)
)