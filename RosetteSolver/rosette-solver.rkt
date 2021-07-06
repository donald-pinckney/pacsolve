#lang rosette

(require "query.rkt")
(require "load-query.rkt")
(require "graph-sketching.rkt")
(require "solution.rkt")
(require "write-solution.rkt")
(require "graph-constraints.rkt")
(require "graph-optimization.rkt")


(define INPUT-SOURCE
  (if (= 2 (vector-length (current-command-line-arguments)))
      (vector-ref (current-command-line-arguments) 0)
      (error "Incorrect number of command line arguments")))

(define QUERY (read-input-query INPUT-SOURCE))

;;; -------------------------------------------
;;; Actually doing the solve!
;;; -------------------------------------------



;; Increase this appropriately to allow more duplicate nodes.
;; A value of 1 means that each version will be in the graph either 0 or 1 times (i.e. no duplicates).
(define MAX-DUPLICATES 1) 

(define G (graph* QUERY MAX-DUPLICATES))

(define (rosette-sol->solution sol)
  (if (sat? sol)
    (solution #t (evaluate G sol))
    (solution #f "Failed to solve constraints :(")))

(define sol
  (optimize
   #:minimize (optimize-graph QUERY G)
   #:guarantee (check-graph QUERY G)))

(write-solution (rosette-sol->solution sol))

