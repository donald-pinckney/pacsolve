#lang rosette

(provide DSL-PRIMITIVES-SYMBOLIC)

(require "graph.rkt")

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
  (define p-groups-list (graph-package-groups-list g))
  (define vn-vecs-list (map package-group-version-nodes-vec p-groups-list))
  (define vn-vec-costs-list 
    (map
      (lambda (vn-vec) 
        (foldl
          (lambda (idx acc)
            (define the-vn (vector-ref vn-vec idx))

            (((fun_v the-vn) (node-active (version-node-node the-vn))) acc)
          )
          init_v
          (range (vector-length vn-vec))))
      vn-vecs-list))
  
  (foldl
    (lambda (pg vn-vec-cost acc)
      (((fun_p pg) vn-vec-cost) acc)
    )
    init_p
    p-groups-list
    vn-vec-costs-list)
  )


; get-cost-val/version-node: version-node -> String -> Number
(define (get-cost-val/version-node vn key)
  (hash-ref (version-node-cost-values vn) key))

; get-cost-val/package-group: package-group -> String -> Number
(define (get-cost-val/package-group pg key) 
  (hash-ref (package-group-cost-values pg) key))

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
  (cons "get-cost-val/version-node" get-cost-val/version-node)
  (cons "get-cost-val/package-group" get-cost-val/package-group)
)))