#lang rosette

;;; -------------------------------------------
;;; RESOLUTION GRAPH DATA STRUCTURE
;;; -------------------------------------------


(provide (struct-out edge))
(provide (struct-out node))
(provide (struct-out version-node))
(provide (struct-out package-group))
(provide (struct-out graph))


; package-idx is NON symbolic integer
; version-idx is symbolic integer/bitvector
(struct edge (package-idx version-idx) #:transparent)

; A maybe-edge is one of:
; - (edge package-idx version-idx)
; - (void)
; The void case represents an edge which can't ever be satisfied (e.g. missing packages)

; active is symbolic boolean
; edges is a list of NON symbolic length, 
;   containing maybe-edges (which have some symbolic fields)
; top-order is symbolic integer
(struct node (active edges top-order) #:transparent)

; version is NON symbolic
; cost-values: [string : number], non symbolic
; node is a node
(struct version-node (version cost-values node) #:transparent)

; package is a non-symbolic string (name of package)
; cost-values: [string : number], non-symbolic
; version-nodes-vec is a vector of NON symbolic length, containing version-node
(struct package-group (package cost-values version-nodes-vec) #:transparent)

; context-node is a node
; package-groups is a list of NON symbolic length, containing package-group
(struct graph (context-node package-groups-list) #:transparent)




;;; ----------------------------------------------
;;; HELPERS FOR TRAVERSING OVER A RESOLUTION GRAPH
;;; ----------------------------------------------

(require "query.rkt")
(require "query-access.rkt")

(provide for/graph-edges)
(provide for/graph-version-nodes)
(provide foldl/graph-version-nodes)

; g : graph
; f : version-node -> package -> ()
(define (for/graph-version-nodes g f)
  (for-each 
    (lambda (p-group)
      (for-each 
        (lambda (v-node)
          (f v-node (package-group-package p-group)))
        (vector->list (package-group-version-nodes-vec p-group))))
    (graph-package-groups-list g)))

; g : graph
; i : acc
; f : version-node -> acc -> acc
(define (foldl/graph-version-nodes g i f)
  (define v-nodes 
    (flatten 
      (map 
        (lambda (p-group) (vector->list (package-group-version-nodes-vec p-group))) 
        (graph-package-groups-list g))))
  (foldl f i v-nodes))

; g : graph
; f : edge -> constraint -> Maybe package -> Maybe version -> node -> ()
(define (for/graph-edges query g f)
  (for/graph-version-nodes g
    (lambda (v-node package)
      (define p-idx (package-index query package))
      (define version (version-node-version v-node))
      (define node (version-node-node v-node))
      (define v-idx (version-index query p-idx version))

      (define deps (parsed-package-version-dep-vec (registry-ref query p-idx v-idx)))
      
      (for-each 
        (lambda (e dep)
          (f e (dep-constraint dep) package version node))
        (node-edges node)
        deps)))

  (for-each 
    (lambda (e dep)
      (f e (dep-constraint dep) #f #f (graph-context-node g)))
    (node-edges (graph-context-node g))
    (context-deps query)))
