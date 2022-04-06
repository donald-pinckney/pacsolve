#lang rosette

(require "query.rkt")
(require "solution.rkt")
(require "query-access.rkt")
(require "solution-graph/graph-interface.rkt")

(require json)

(provide write-solution)

(define (flatten-graph-idx query g e p-counts v-counts)

  (define normal-dst-data (normal-node/get-data g e))
  (define pkg-grp-ref (normal-node-data-pkg-grp-ref normal-dst-data))
  (define name (package-group-data-name (package-group/get-data g pkg-grp-ref)))
  (define version (normal-node-data-version normal-dst-data))

  (define query-pkg-idx (package-index query name))
  (define query-version-idx (version-index query query-pkg-idx version))
  
  (define prev-p-sum
    (apply +
      (for/list ([prev-p-idx (range query-pkg-idx)]
                 [p-count p-counts])
        p-count)))

  (define vn-counts (list-ref v-counts query-pkg-idx))

  (define prev-v-sum
    (apply +
      (for/list ([prev-v-idx (range query-version-idx)]
                 [vn-count vn-counts])
        vn-count)))

  (+ 1 prev-p-sum prev-v-sum))

(define (version->json query v) 
  (serialize-version query v))

(define (resolved-vertex->json query p v) 
  (make-hash (list (cons 'type "ResolvedPackageVertex") (cons 'package p) (cons 'version (version->json query v)))))


(struct temp-graph-node (vertex-data edge-data) #:transparent)

(define (graph->json query g)
  (define ctx-ref (graph/get-context-node g))

  (define context-edge-refs (node/get-edges g ctx-ref))

  (define pkg-grp-refs (graph/get-package-groups g))

  (define version-counts
    (for/list ([pkg-grp-ref pkg-grp-refs])
      (define node-refs (package-group/get-nodes g pkg-grp-ref))
      (for/list ([node-ref node-refs])
        (define data (node/get-data g node-ref))
        (if (node-data-active? data) 1 0))))
  

  (define package-counts (map (lambda (xs) (apply + xs)) version-counts))

  (define vertices-and-edges-flattened 
    (flatten
      (for/list ([pkg-grp-ref pkg-grp-refs])
        (define pkg-name (package-group-data-name (package-group/get-data g pkg-grp-ref)))
        (define node-refs (package-group/get-nodes g pkg-grp-ref))

        (for/list ([node-ref node-refs])
          (define normal-data (normal-node/get-data g node-ref))
          (define version (normal-node-data-version normal-data))
          (define data (normal-node-data-node-data normal-data))
          (if
            (node-data-active? data)
            (list 
              (temp-graph-node (resolved-vertex->json query pkg-name version) (node/get-edges g node-ref)))
            '())))))

  (define vertices
    (cons (make-hash (list (cons 'type "RootContextVertex")))
          (map (lambda (vert-and-edge) (temp-graph-node-vertex-data vert-and-edge)) vertices-and-edges-flattened)))

  (define edge-data
    (cons
     context-edge-refs
     (map (lambda (vert-and-edge) (temp-graph-node-edge-data vert-and-edge)) vertices-and-edges-flattened)))

  (define edge-flat-indices
    (map
     (lambda (edges)
       (map
        (lambda (e)
          (flatten-graph-idx query g e package-counts version-counts))
        edges))
     edge-data))

  (make-hash (list (cons 'vertices vertices) (cons 'out_edge_array edge-flat-indices) (cons 'context_vertex 0))))



(define (sol->json query sol)
  (if (solution-success sol)
      (make-hash (list (cons 'success #t) (cons 'graph (graph->json query (solution-graphOrMessage sol)))))
      (make-hash (list (cons 'success #f) (cons 'error (solution-graphOrMessage sol))))))



(define (write-solution output-path query sol)
  (with-output-to-file output-path (lambda () (write-json (sol->json query sol))) #:exists 'replace))


