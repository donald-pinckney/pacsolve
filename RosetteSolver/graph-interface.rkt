#lang rosette

(require racket/generic)

(provide
  gen:solution-graph
  solution-graph?
  graph/get-context-node
  graph/get-package-groups
  package-group/get-nodes
  node/get-edges
  package-group/get-data
  normal-node/get-data
  node/get-data)

(provide (struct-out package-group-data))
(provide (struct-out normal-node-data))
(provide (struct-out node-data))


; Interface design:

; Abstract external types:
; PackageGroupRef
; ContextNodeRef
; NormalNodeRef

; Concrete external types:
(struct package-group-data (name cost-values-hash) #:transparent)
(struct normal-node-data (version cost-values-hash node-data) #:transparent)
(struct node-data (active? top-order) #:transparent)




; Functions:

(define-generics solution-graph
  ; Graph -> ContextNodeRef
  [graph/get-context-node       solution-graph] 

  ; Graph -> List PackageGroupRef
  [graph/get-package-groups   solution-graph]

  ; Graph -> PackageGroupRef -> List NormalNodeRef
  [package-group/get-nodes    solution-graph pkg-grp-ref] 

  ; Graph -> ContextNodeRef | NormalNodeRef -> List (NormalNodeRef* | void?)
  [node/get-edges               solution-graph node-ref] 
  
  ; Graph -> PackageGroupRef -> package-group-data
  [package-group/get-data       solution-graph pkg-grp-ref] 
  
  ; Graph -> NormalNodeRef -> normal-node-data
  [normal-node/get-data         solution-graph node-ref] 
  
  ; Graph -> ContextNodeRef | NormalNodeRef -> node-data
  [node/get-data                solution-graph node-ref]) 
