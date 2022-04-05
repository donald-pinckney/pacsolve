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





;; Graph Interface Implementation


; Internal types:
; PackageGroup
; Node
; VersionNode



;;; (struct package-group-ref (pkg-idx) #:transparent)
;;; (struct node-ref-context () #:transparent)
;;; (struct node-ref-normal (pkg-idx version-idx) #:transparent)

;;; (define (graph/get-context-node g) (node-ref-context))

;;; (define (graph/foldl-package-groups g acc f)
;;;   (define refs 
;;;     (map 
;;;       package-group-ref 
;;;       (range (length (graph-package-groups-list g)))))
  
;;;   (foldl f acc refs))


;;; (define (package-group/foldl-nodes g pkg-grp-ref acc f)
;;;   (define pkg-idx (package-group-ref-pkg-idx pkg-grp-ref))
;;;   (define pkg-group (graph/package-group-ref g pkg-grp-ref))
;;;   (define versions-vec (package-group-version-nodes-vec pkg-group))
;;;   (define num-bits (integer-length (vector-length versions-vec)))
;;;   (define bv-type (bitvector num-bits))
;;;   (define refs 
;;;     (map 
;;;       (lambda (version-idx) (node-ref-normal pkg-idx (bv version-idx bv-type)))
;;;       (range (vector-length versions-vec))))
;;;   (foldl f acc refs))

;;; (define (node/foldl-edges g node-ref acc f)
;;;   (define the-node (graph/node-ref g node-ref))

;;;   (define edges (node-edges the-node))
;;;   (define dst-refs 
;;;     (map 
;;;       (lambda (e) 
;;;         (node-ref-normal 
;;;           (edge-package-idx e) 
;;;           (edge-version-idx e))) 
;;;       edges))
  
;;;   (foldl f acc dst-refs))


;;; (define (package-group/get-data g pkg-grp-ref)
;;;   (define pkg-grp (graph/package-group-ref g pkg-grp-ref))
;;;   (package-group-data 
;;;     (package-group-package pkg-group)
;;;     (package-group-cost-values pkg-group)))

;;; (define (normal-node/get-data g node-ref)
;;;   (define the-version-node (graph/normal-node-ref g node-ref))
;;;   (normal-node-data 
;;;     (package-group-ref (node-ref-normal-pkg-grp-ref node-ref))
;;;     (version-node-version the-version-node)
;;;     (version-node-cost-values the-version-node)
;;;     (node/get-data g node-ref)))

;;; (define (node/get-data g node-ref)
;;;   (define the-node (graph/node-ref g node-ref))
;;;   (node-data 
;;;     (node-active the-node)
;;;     (node-top-order the-node)))


;;; ; Helpers

;;; ; graph/package-group-ref: Graph -> PackageGroupRef -> PackageGroup
;;; (define (graph/package-group-ref g pkg-grp-ref)
;;;   (list-ref (graph-package-groups-list g) (package-group-ref-pkg-idx pkg-grp-ref)))

;;; ; graph/node-ref: Graph -> ContextNodeRef | NormalNodeRef -> Node
;;; (define (graph/node-ref g node-ref)
;;;   (if (node-ref-context? node-ref)
;;;       (graph-context-node g)
;;;       (version-node-node (graph/normal-node-ref g node-ref))))

;;; ; graph/normal-node-ref: Graph -> NormalNodeRef -> VersionNode
;;; (define (graph/normal-node-ref g node-ref)
;;;   (vector-ref-bv 
;;;     (package-group-version-nodes-vec 
;;;       (list-ref (graph-package-groups-list g) (node-ref-pkg-idx node-ref)))
;;;     (node-ref-version-idx node-ref)))