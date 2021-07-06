#lang rosette

;;; -------------------------------------------
;;; OPTIMIZATION CRITERIA
;;; -------------------------------------------

(provide optimize-graph)

(require "graph.rkt")
(require "query.rkt")

(define (graph-num-vertices _query g)
  (foldl/graph-version-groups
   g
   0
   (lambda (v-group sum)
     (+ sum (version-group-node-count v-group)))))

(define (lookup-optim-fn name)
  (match name
    ["graph-num-vertices" graph-num-vertices]))

(define (optimize-graph query g)
  (define optim-fns (map lookup-optim-fn (query-min-criteria query)))

  (map (lambda (fn) (fn query g)) optim-fns))
                            