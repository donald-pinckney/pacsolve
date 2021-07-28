#lang racket

(require "graph.rkt")
(require "query.rkt")
(require "solution.rkt")
(require json)

(provide write-solution)

(define (flatten-graph-idx e p-counts v-counts)
  (define p-idx (edge-package-idx e))
  (define v-idx (edge-version-idx e))
  (define n-idx (edge-node-idx e))
  
  (define prev-p-sum (apply + (map (lambda (prev-p-idx) (list-ref p-counts prev-p-idx)) (range p-idx))))
  (define vg-counts (list-ref v-counts p-idx))
  (define prev-v-sum (apply + (map (lambda (prev-v-idx) (list-ref vg-counts prev-v-idx)) (range v-idx))))
  (+ 1 prev-p-sum prev-v-sum n-idx))

(define (version->json query v) 
  (serialize-version query v))

(define (resolved-vertex->json query p v) 
  (make-hash (list (cons 'type "ResolvedPackageVertex") (cons 'package p) (cons 'version (version->json query v)))))

(struct temp-graph-node (vertex-data edge-data) #:transparent)

(define (graph->json query g)
  (define context-edges (node-edges (graph-context-node g)))
  (define p-groups (graph-package-groups-list g))
  (define version-counts
    (map
     (lambda (pg)
       (map
        (lambda (vg-idx)
          (define vg (vector-ref (package-group-version-groups-vec pg) vg-idx))
          (version-group-node-count vg))
        (range (vector-length (package-group-version-groups-vec pg)))))
     p-groups))
  (define package-counts (map (lambda (xs) (apply + xs)) version-counts))

  (define vertices-and-edges-flattened 
    (flatten
     (map
      (lambda (pg)
        (define p (package-group-package pg))
        (map
         (lambda (vg-idx)
           (define vg (vector-ref (package-group-version-groups-vec pg) vg-idx))
           (define v (version-group-version vg))
           (map
            (lambda (n)
              (temp-graph-node (resolved-vertex->json query p v) (node-edges n)))
            (version-group-nodes-list vg)))
         (range (vector-length (package-group-version-groups-vec pg)))))
      p-groups)))

  (define vertices
    (cons (make-hash (list (cons 'type "RootContextVertex")))
          (map (lambda (pr) (temp-graph-node-vertex-data pr)) vertices-and-edges-flattened)))

  (define edge-data
    (cons
     context-edges
     (map (lambda (pr) (temp-graph-node-edge-data pr)) vertices-and-edges-flattened)))

  (define edge-flat-indices
    (map
     (lambda (edges)
       (map
        (lambda (e)
          (flatten-graph-idx e package-counts version-counts))
        edges))
     edge-data))

  (make-hash (list (cons 'vertices vertices) (cons 'out_edge_array edge-flat-indices) (cons 'context_vertex 0))))

(define (sol->json query sol)
  (if (solution-success sol)
      (make-hash (list (cons 'success #t) (cons 'graph (graph->json query (solution-graphOrMessage sol)))))
      (make-hash (list (cons 'success #f) (cons 'error (solution-graphOrMessage sol))))))


(define OUTPUT-PATH
  (if (= 2 (vector-length (current-command-line-arguments)))
      (vector-ref (current-command-line-arguments) 1)
      (error "Incorrect number of command line arguments")))

(define (write-solution query sol)
  (with-output-to-file OUTPUT-PATH (lambda () (write-json (sol->json query sol))) #:exists 'replace))


