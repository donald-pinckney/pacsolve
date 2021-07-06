#lang rosette

; (require "query.rkt")
; (require "query-access.rkt")
(require "graph-sketching.rkt")
(require "solution.rkt")
(require "write-solution.rkt")
(require "graph-constraints.rkt")
(require "graph-optimization.rkt")


;;; -------------------------------------------
;;; Actually doing the solve!
;;; -------------------------------------------



;; Increase this appropriately to allow more duplicate nodes.
;; A value of 1 means that each version will be in the graph either 0 or 1 times (i.e. no duplicates).
(define MAX-DUPLICATES 1) 

(define G (graph* MAX-DUPLICATES))

(define (rosette-sol->solution sol)
  (if (sat? sol)
    (solution #t (evaluate G sol))
    (solution #f "Failed to solve constraints :(")))

(define sol
  (optimize
   #:minimize (optimize-graph G)
   #:guarantee (check-graph G)))

(write-solution (rosette-sol->solution sol))

