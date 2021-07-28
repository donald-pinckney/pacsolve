#lang rosette

(require rosette/lib/destruct)
(require "graph.rkt")
(require "query.rkt")
(require "query-access.rkt")
(require "consistency.rkt")

(provide check-graph)

;;; -------------------------------------------
;;; CONSTRAINT GENERATION
;;; -------------------------------------------


;;; *** Constraints part 1: Checking well-formedness (edges have valid indices into node lists), and we have non-negative number of vertices
(define (check-edge-well-formed e g)
  (define p (edge-package-idx e)) ; not symbolic
  (define v (edge-version-idx e)) ; symbolic, already properly bounded
  (define n (edge-node-idx e)) ; symbolic, not propertly bounded by size of destination vector

  (define p-group (list-ref (graph-package-groups-list g) p))
  (define v-group (vector-ref (package-group-version-groups-vec p-group) v))
  
  (assert (<= 0 n))
  (assert (< n (version-group-node-count v-group))))
  
(define (check-version-group-well-formed v-group _package)
  (assert (<= 0 (version-group-node-count v-group))))

(define (check-graph-well-formed query g)
  (for/graph-edges query g (lambda (e _constraint _p _v _n) (check-edge-well-formed e g)))
  (for/graph-version-groups g check-version-group-well-formed))


;;; *** Constraints part 2: Checking that the graph is a DAG. This check can simply be omitted to allow cyclic graphs
(define (check-graph-acyclic query g)
  (assert (= 0 (node-top-order (graph-context-node g))))
  (for/graph-edges query g
    (lambda (e c _sp _sv src-node)
      (define dp-idx (edge-package-idx e)) ; not symbolic
      (define dv-idx (edge-version-idx e)) ; symbolic
      (define dn-idx (edge-node-idx e)) ; symbolic

      (define dp-group (list-ref (graph-package-groups-list g) dp-idx))
      (define dv-group (vector-ref (package-group-version-groups-vec dp-group) dv-idx))
      (define dn (list-ref (version-group-nodes-list dv-group) dn-idx)) ; the destination node
      
      (assert (< (node-top-order src-node) (node-top-order dn))))))
                                             
  

;;; *** Constraints part 3: Checking that the graph satisfies all dependency constraints
(define (sat/version-constraint v-s c)
  #t)
  
;; TODO: Re-enable this
  ; (destruct c
  ;   [(constraint-wildcardMajor) #t]
  ;   [(constraint-exactly cv) (equal? v-s cv)]))

(define (check-graph-sat-deps query g)
  (for/graph-edges query g (lambda (e constraint _p _v _n)
    (define dest-version (car (registry-ref query (edge-package-idx e) (edge-version-idx e))))
    (assert (sat/version-constraint dest-version constraint)))))


;;; *** Constraints part 4: Checking that the graph contains pairwise consistent versions of the same package, parameterized by relation `r`
(define (check-graph-consistent query g r)
  (for-each
   (lambda (p-idx)
     (define n-vers (registry-num-versions query p-idx))
     (define p-group (list-ref (graph-package-groups-list g) p-idx)) ; the package group in the graph
     
     (for-each
      (lambda (v1-idx)
        (define v1 (car (registry-ref query p-idx v1-idx)))
        (define v1-group (vector-ref (package-group-version-groups-vec p-group) v1-idx)) ; the version group for v1
        (define v1-count (version-group-node-count v1-group))
        
        (for-each
         (lambda (v2-idx)
           (define v2 (car (registry-ref query p-idx v2-idx)))
           (define v2-group (vector-ref (package-group-version-groups-vec p-group) v2-idx)) ; the version group for v2
           (define v2-count (version-group-node-count v2-group))

           (if (not (r v1 v2)) ; v1 and v2 are concrete
               (assert (not (and (< 0 v1-count) (< 0 v2-count)))) ; v1-count and v2-count are symbolic
               #t))
         (range v1-idx)))
      (range n-vers)))
   (range (registry-num-packages query))))

;;; *** Final constraint generation
(define (check-graph query g)
  (define consistency-rel 
    (match (options-consistency (query-options query))
      ["pip" consistency/pip]
      ["npm" consistency/npm]))
  (define check-acyclic (options-check-acyclic (query-options query)))

  (check-graph-well-formed query g)
  (check-graph-sat-deps query g)
  (if check-acyclic (check-graph-acyclic query g) #t)
  (check-graph-consistent query g consistency-rel))