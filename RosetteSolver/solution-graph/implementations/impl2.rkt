#lang rosette

;;; -------------------------------------------
;;; GRAPH DATA STRUCTURE DEFINITION
;;; -------------------------------------------


; package-idx is NON symbolic integer
; num-vers is a NON symbolic integer
; version-idx is symbolic integer/bitvector
(struct edge (package-idx num-vers version-idx) #:transparent)

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



(require "../graph-interface.rkt")

;;; -------------------------------------------
;;; GRAPH INTERFACE IMPLEMENTATION
;;; -------------------------------------------

(struct package-group-ref (pkg-idx) #:transparent)
(struct node-ref-context () #:transparent)
(struct node-ref-normal (pkg-idx num-vers version-idx) #:transparent)


; context-node is a node
; package-groups is a list of NON symbolic length, containing package-group
(struct graph (context-node package-groups-list)
  #:transparent
  #:methods gen:solution-graph
  [
   (define (graph/get-context-node g) (node-ref-context))

   (define (graph/get-package-groups g)
     (map
      package-group-ref
      (range (length (graph-package-groups-list g)))))


   (define (package-group/get-nodes g pkg-grp-ref )
     (define pkg-idx (package-group-ref-pkg-idx pkg-grp-ref))
     (define pkg-group (graph/package-group-ref g pkg-grp-ref))
     (define versions-vec (package-group-version-nodes-vec pkg-group))
     (define num-bits (integer-length (vector-length versions-vec)))
     (define bv-type (bitvector num-bits))
     (map
      (lambda (version-idx) (node-ref-normal pkg-idx (bv version-idx bv-type)))
      (range (vector-length versions-vec))))


   (define (node/get-edges g node-ref)
     (define the-node (graph/node-ref g node-ref))

     (define edges (node-edges the-node))
     (define dst-refs
       (map
        (lambda (e)
          (if (void? e)
              (void)
              (node-ref-normal
               (edge-package-idx e)
               (edge-num-vers e)
               (edge-version-idx e))))
        edges))

     dst-refs)


   (define (package-group/get-data g pkg-grp-ref)
     (define pkg-group (graph/package-group-ref g pkg-grp-ref))
     (package-group-data
      (package-group-package pkg-group)
      (package-group-cost-values pkg-group)))

   (define (normal-node/get-data g node-ref)
     (define the-version-node (graph/normal-node-ref g node-ref))
     (normal-node-data
      ;; TODO : what do we give it here for *num-vers* ?
      (package-group-ref (node-ref-normal-pkg-idx node-ref))
      (version-node-version the-version-node)
      (version-node-cost-values the-version-node)
      (node/get-data g node-ref)))

   (define (node/get-data g node-ref)
     (define the-node (graph/node-ref g node-ref))
     (node-data
      (node-active the-node)
      (node-top-order the-node)))
   ])


; Helper functions for interface implementation

; graph/package-group-ref: Graph -> PackageGroupRef -> PackageGroup
(define (graph/package-group-ref g pkg-grp-ref)
  (list-ref (graph-package-groups-list g) (package-group-ref-pkg-idx pkg-grp-ref)))

; graph/node-ref: Graph -> ContextNodeRef | NormalNodeRef -> Node
(define (graph/node-ref g node-ref)
  (if (node-ref-context? node-ref)
      (graph-context-node g)
      (version-node-node (graph/normal-node-ref g node-ref))))

; graph/normal-node-ref: Graph -> NormalNodeRef -> VersionNode
(define (graph/normal-node-ref g node-ref)
  (vector-ref-bv
   (package-group-version-nodes-vec
    (list-ref (graph-package-groups-list g) (node-ref-normal-pkg-idx node-ref)))
   (node-ref-normal-version-idx node-ref)))






;;; -------------------------------------------
;;; SYMBOLIC GRAPH GENERATION (SKETCHING)
;;; -------------------------------------------


(require "../../query.rkt")
(require "../../query-access.rkt")



(provide generate-graph)

; generate-fin generates a symbolic integer x such that 0 <= x < n

;; TODO: purpose
(define (generate-fin n)
  (if
   (< n 1)
   (bv 0 (bitvector 1))
   (begin
     (define num-bits (integer-length n))
     (define bv-n (bv n (bitvector num-bits)))
     (define-symbolic* x (bitvector num-bits))
     (assert (bvule x bv-n))
     x)))

; (apply choose* (range n))) ;; TODO: play with representation

(define (generate-node query deps)
  (define-symbolic* active boolean?) ;; TODO: play with representation
  (define-symbolic* ts integer?) ;; TODO: play with representation
  (node
   active
   (map
    (lambda (dep)
      (match (package-index query (dep-package dep))
        [-1 (void)]
        [pkg-idx
         (begin
           (define vers-sat
             (vector-map (lambda (v-p) ((dep-constraint dep) (parsed-package-version-version v-p)))
                         (parsed-package-pv-vec (vector-ref (registry-vec (query-registry query)) pkg-idx))))
           (define num-vers-sat (count identity (vector->list vers-sat)))
           (edge
            num-vers-sat
            pkg-idx
            (generate-fin num-vers-sat)))]
        ))
    deps)
   ts))

(define (generate-version-node query version cost-values deps)
  (version-node
   version
   cost-values
   (generate-node query deps)))

(define (generate-package-group query package)
  (define p-idx (package-index query package))
  (define version-idxs (range (registry-num-versions query p-idx)))
  (define cost-values (registry-package-cost-values query p-idx))

  (define version-nodes
    (map
     (lambda (version-idx)
       (define parsed-pv (registry-ref query p-idx version-idx))
       (generate-version-node
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
(define (generate-graph query)
  (define context-node (generate-node query (context-deps query)))
  (define p-idxs (range (registry-num-packages query)))
  (define package-groups
    (map
     (lambda (p-idx)
       (generate-package-group query (registry-package-name query p-idx)))
     p-idxs))

  (graph context-node package-groups))
