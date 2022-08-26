#lang rosette

(require "../query.rkt")
(require "../query-access.rkt")
(require "graph-interface.rkt")

(provide check-graph)

;;; -------------------------------------------
;;; CONSTRAINT GENERATION
;;; -------------------------------------------



;;; *** Constraints part 1: Checking that the graph is a DAG.
;;; This check can simply be omitted to allow cyclic graphs
(define (check-graph-acyclic query g)
  (define ctx-ref (graph/get-context-node g))
  (define ctx-data (node/get-data g ctx-ref))
  (assert (= 0 (node-data-top-order ctx-data)))

  (define src-nodes 
    (cons ctx-ref
          (append-map 
            (lambda (pg) (package-group/get-nodes g pg))
            (graph/get-package-groups g))))

  (for ([src-node src-nodes])
    (define src-data (node/get-data g src-node))
    (define src-active? (node-data-active? src-data))
    (define src-top-order (node-data-top-order src-data))

    (define dst-edges (node/get-edges g src-node))
    ;; e is a maybe-edge, it might be (void)
    ;; We wrap all edge operations around (if src-active? ...), so that
    ;; the edge operations would only fail in the case that the node is not active.
    ;; Then, Rosette will solve for making nodes be NOT active, if they have (void) edges.
    (if src-active?
        (for ([dst-node-maybe dst-edges])
          (assert (not (void? dst-node-maybe)))
          (define dst-top-order (node-data-top-order (node/get-data g dst-node-maybe)))
          (assert (< src-top-order dst-top-order)))
        (void))))
      



;;; *** Constraints part 2: Checking that the graph satisfies all dependency constraints
(define (sat/version-constraint v-s c)
  (c v-s))

(define (check-graph-sat-deps query g)
  (define ctx-ref (graph/get-context-node g))
  (define ctx-data (node/get-data g ctx-ref))
  (assert (node-data-active? ctx-data))

  (define src-pkg-grp-refs (graph/get-package-groups g))
  (for ([src-pkg-grp-ref src-pkg-grp-refs])
    (define src-pkg-name (package-group-data-name (package-group/get-data g src-pkg-grp-ref)))
    (define src-pkg-idx-query (package-index query src-pkg-name))

    (define src-nodes (package-group/get-nodes g src-pkg-grp-ref))
    (for ([node-src-ref src-nodes])
      (define src-normal-data (normal-node/get-data g node-src-ref))
      (define src-version (normal-node-data-version src-normal-data))
      (define src-active? (node-data-active? (normal-node-data-node-data src-normal-data)))
      (define src-version-idx-query (version-index query src-pkg-idx-query src-version))

      (define src-query-deps 
        (parsed-package-version-dep-vec 
          (registry-ref query src-pkg-idx-query src-version-idx-query)))

      ;; See comment inside check-graph-acyclic about dealing with (void) edges.
      (if src-active?
          (check-graph-sat-deps/single-node g node-src-ref src-query-deps)
          (void))))


  (check-graph-sat-deps/single-node g ctx-ref (context-deps query)))


; check-graph-sat-deps/single-node: Graph -> List (NormalNodeRef* | void?) -> List Dependencies
(define (check-graph-sat-deps/single-node g src-node-ref src-query-dependencies)
  (define src-edge-dst-nodes (node/get-edges g src-node-ref))
  (define src-query-constraints (map dep-constraint src-query-dependencies))

  (for ([node-dst-ref-maybe src-edge-dst-nodes] 
        [constraint src-query-constraints])
    (assert (not (void? node-dst-ref-maybe)))
    (define dst-normal-data (normal-node/get-data g node-dst-ref-maybe))
    (define dst-version (normal-node-data-version dst-normal-data))
    (define dst-active? (node-data-active? (normal-node-data-node-data dst-normal-data)))

    (assert dst-active?)
    (assert (sat/version-constraint dst-version constraint))))




;;; *** Constraints part 3: Checking that the graph contains pairwise consistent versions of the same package, parameterized by relation `r`
(define (check-graph-consistent query g r)
  (define pkg-group-refs (graph/get-package-groups g))
  
  (for ([pkg-grp-ref pkg-group-refs])
    (define all-node-refs (package-group/get-nodes g pkg-grp-ref))
    (define all-node-data (map (lambda (n) (normal-node/get-data g n)) all-node-refs))
    (define node-data-combos (combinations all-node-data 2))

    (for ([combo node-data-combos])
      (define data1 (car combo))
      (define data2 (cadr combo))
      
      (define v1 (normal-node-data-version data1))
      (define v2 (normal-node-data-version data2))

      (define active1? (node-data-active? (normal-node-data-node-data data1)))
      (define active2? (node-data-active? (normal-node-data-node-data data2)))
      
      (if (not (r v1 v2))
          (assert (not (and active1? active2?)))
          (void)))))


;;; *** Final constraint generation
(define (check-graph query g pip-mode)
  (define (consistency-rel v1 v2) (evaluate-consistency query v1 v2))
  (define check-acyclic (options-check-acyclic (query-options query)))

  (check-graph-sat-deps query g)
  (if check-acyclic (check-graph-acyclic query g) #t)
  (if pip-mode #t (check-graph-consistent query g consistency-rel))
)
