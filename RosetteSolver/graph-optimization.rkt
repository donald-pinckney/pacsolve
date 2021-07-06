#lang rosette

;;; -------------------------------------------
;;; OPTIMIZATION CRITERIA
;;; -------------------------------------------

(provide optimize-graph)

(require "graph.rkt")

(define (graph-num-vertices g)
  (foldl/graph-version-groups
   g
   0
   (lambda (v-group sum)
     (+ sum (version-group-node-count v-group)))))

(define (optimize-graph g)
  ; For now we just minimize the number of vertices
  (list
   (graph-num-vertices g)))
                            