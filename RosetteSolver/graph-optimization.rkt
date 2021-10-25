#lang rosette

;;; -------------------------------------------
;;; OPTIMIZATION CRITERIA
;;; -------------------------------------------

(provide optimize-graph)

(require "graph.rkt")
(require "query.rkt")

(define (graph-num-vertices _query g)
  (foldl/graph-version-nodes
    g
    0
    (lambda (v-node sum)
      (+ sum (if (node-active (version-node-node v-node)) 1 0)))))

(define (lookup-optim-fn name)
  (match name
    ["graph-num-vertices" graph-num-vertices]))

(define (optimize-graph query g)
  (define optim-fns (map lookup-optim-fn (options-min-criteria (query-options query))))

  (map (lambda (fn) (fn query g)) optim-fns))
                            