#lang rosette

;;; -------------------------------------------
;;; OPTIMIZATION OBJECTIVES
;;; -------------------------------------------

(provide optimize-graph)

(require "query.rkt")
(require "function-dsl.rkt")
(require "dsl-primitives-symbolic.rkt")

(define (evaluate-objective query g obj-name)
  (eval-dsl-function
    DSL-PRIMITIVES-SYMBOLIC
    (query-functions-hash query)
    obj-name
    (list g)))

(define (optimize-graph query g)
  (map 
    (lambda (obj) (evaluate-objective query g obj)) 
    (options-min-objectives-names (query-options query))))
                            