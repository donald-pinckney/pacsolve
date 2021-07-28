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

(display QUERY)

;;; -------------------------------------------
;;; Actually doing the solve!
;;; -------------------------------------------


(define G (graph* QUERY))

(define (rosette-sol->solution sol)
  (if (sat? sol)
    (solution #t (evaluate G sol))
    (solution #f "Failed to solve constraints :(")))

(define sol
  (optimize
   #:minimize (optimize-graph QUERY G)
   #:guarantee (check-graph QUERY G)))

(display "\n\n")
(display sol)
(write-solution QUERY (rosette-sol->solution sol))

