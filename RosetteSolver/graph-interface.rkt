#lang rosette

(require racket/generic)

(provide
  gen:solution-graph
  solution-graph?
  graph/get-context-node
  graph/foldl-package-groups
  package-group/foldl-nodes
  node/foldl-edges
  pacakge-group/get-data
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
(struct normal-node-data (pkg-grp-ref version cost-values-hash node-data) #:transparent)
(struct node-data (active? top-order) #:transparent)




; Functions:

(define-generics solution-graph
  ; Graph -> ContextNodeRef
  [graph/get-context-node       g] 

  ; Graph -> 'a -> (PackageGroupRef -> 'a -> 'a) -> 'a
  [graph/foldl-package-groups   g acc f]

  ; Graph -> PackageGroupRef -> 'a -> (NormalNodeRef -> 'a -> 'a) -> 'a
  [package-group/foldl-nodes    g pkg-grp-ref acc f] 
  
  ; Graph -> ContextNodeRef | NormalNodeRef -> 'a -> (NormalNodeRef* -> 'a -> 'a) -> 'a
  [node/foldl-edges             g node-ref acc f] 
  
  ; Graph -> PackageGroupRef -> package-group-data
  [pacakge-group/get-data       g pkg-grp-ref] 
  
  ; Graph -> NormalNodeRef -> normal-node-data
  [normal-node/get-data         g node-ref] 
  
  ; Graph -> ContextNodeRef | NormalNodeRef -> node-data
  [node/get-data                g node-ref]) 
