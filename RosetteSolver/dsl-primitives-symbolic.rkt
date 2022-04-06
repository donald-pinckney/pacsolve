#lang rosette

(provide DSL-PRIMITIVES-SYMBOLIC)

(require "graph-interface.rkt")

(define (make-json-hash assocs)
  (make-hasheq (map (lambda (p) (cons (string->symbol (car p)) (cdr p))) assocs)))

; foldl/graph: 
; Graph 
; -> AccV 
; -> (version-node -> Symb Boolean -> AccV -> AccV) 
; -> AccP 
; -> (package-group -> AccV -> AccP -> AccP) 
; -> AccP
(define (foldl/graph g init_v fun_v init_p fun_p)
  (define p-groups-list (graph/get-package-groups g))
  (define nodes-list-list (map (lambda (pg) (package-group/get-nodes g pg)) p-groups-list))
  (define node-list-costs
    (map
      (lambda (node-list)
        (foldl
          (lambda (node-ref acc)
            (define ref-normal-node-data (normal-node/get-data g node-ref))
            (define ref-node-data (normal-node-data-node-data ref-normal-node-data))
            (((fun_v ref-normal-node-data) (node-data-active? ref-node-data)) acc)
          )
          init_v
          node-list))
      nodes-list-list))

  (foldl
    (lambda 
      (pg-ref node-list-cost acc)
        (define pg-data (package-group/get-data g pg-ref))
        (((fun_p pg-data) node-list-cost) acc))
    init_p
    p-groups-list
    node-list-costs))


(define (get-cost-val/version-node vn key)
  (hash-ref (normal-node-data-cost-values-hash vn) (string->symbol key)))

(define (get-cost-val/package-group pg key)
  (hash-ref (package-group-data-cost-values-hash pg) (string->symbol key)))

;; Loaded for functions: "constraintInterpretation" and optimization functions
(define DSL-PRIMITIVES-SYMBOLIC (make-immutable-hash (list
  (cons "make-json-hash" make-json-hash) ;; might be wrong
  (cons "list" list)
  (cons "cons" cons)
  (cons "&&" &&)
  (cons "||" ||)
  (cons "apply" (lambda (f x) (f x)))
  (cons "not" not)
  (cons "vector-ref" vector-ref)
  (cons "<" <)
  (cons "==" =)
  (cons ">" >)

  ;; Additional primitive ops for optimization function evaluation
  (cons "foldl/graph" foldl/graph)
  ; ite: Boolean -> A -> A -> A
  (cons "ite" (lambda (b x y) (if b x y)))
  (cons "+" +)
  (cons "*" *)
  (cons "-" -)
  (cons "get-cost-val/version-node" get-cost-val/version-node)
  (cons "get-cost-val/package-group" get-cost-val/package-group)
)))