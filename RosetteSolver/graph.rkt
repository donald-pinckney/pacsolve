#lang rosette

;;; -------------------------------------------
;;; RESOLUTION GRAPH DATA STRUCTURE
;;; -------------------------------------------


(provide (struct-out edge))
(provide (struct-out node))
(provide (struct-out version-group))
(provide (struct-out package-group))
(provide (struct-out graph))

(struct edge (package-idx version-idx node-idx) #:transparent)
(struct node (edges top-order) #:transparent)
(struct version-group (version node-count nodes-list) #:transparent)
(struct package-group (package version-groups-vec) #:transparent)
(struct graph (context-node package-groups-list) #:transparent)




;;; ----------------------------------------------
;;; HELPERS FOR TRAVERSING OVER A RESOLUTION GRAPH
;;; ----------------------------------------------

(require "query.rkt")
(require "query-access.rkt")

(provide for/graph-edges)
(provide for/graph-version-groups)
(provide foldl/graph-version-groups)

; g : graph
; f : version-group -> package -> ()
(define (for/graph-version-groups g f)
  (for-each (lambda (p-group)
              (for-each (lambda (v-group)
                          (f v-group (package-group-package p-group)))
                        (vector->list (package-group-version-groups-vec p-group))))
            (graph-package-groups-list g)))

; g : graph
; i : acc
; f : version-group -> acc -> acc
(define (foldl/graph-version-groups g i f)
  (define v-groups (flatten (map (lambda (p-group) (vector->list (package-group-version-groups-vec p-group))) (graph-package-groups-list g))))
  (foldl f i v-groups))

; g : graph
; f : edge (out) -> constraint -> package -> version -> node -> ()
(define (for/graph-edges query g f)
  (for/graph-version-groups g
    (lambda (v-group package)
      (define p-idx (package-index query package))
      (define v-idx (version-index query p-idx (version-group-version v-group)))

      (define deps (cdr (registry-ref query p-idx v-idx)))

      (for-each (lambda (node)
                  (for-each (lambda (e dep)
                              (f e (dep-constraint dep) package (version-group-version v-group) node))
                            (node-edges node)
                            deps))
                (version-group-nodes-list v-group))))                   

  (for-each (lambda (e dep)
              (f e (dep-constraint dep) #f #f (graph-context-node g)))
            (node-edges (graph-context-node g))
            (context-deps query)))
