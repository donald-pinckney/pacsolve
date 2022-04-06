#lang rosette

; (current-bitwidth 18) ; 32

(require rosette/solver/smt/z3)

(define z3-path (getenv "Z3_ABS_PATH"))
(display z3-path)

(if z3-path
  (current-solver
    (z3 
      #:path z3-path
      #:options (hash ':model.user_functions "false")))
  (void))

(define z3-debug-dir (getenv "Z3_DEBUG"))
(if z3-debug-dir (output-smt z3-debug-dir) (void))


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

(define OUTPUT-PATH
  (if (= 2 (vector-length (current-command-line-arguments)))
      (vector-ref (current-command-line-arguments) 1)
      (error "Incorrect number of command line arguments")))

(define QUERY (read-input-query INPUT-SOURCE))

;;; -------------------------------------------
;;; Actually doing the solve!
;;; -------------------------------------------


(define G (graph* QUERY))

(define (rosette-sol->solution sol)
  (if (sat? sol)
    (solution #t (evaluate G sol))
    (solution #f "Failed to solve constraints :(")))

; (pretty-display (optimize-graph QUERY G))

(define sol
  (optimize
   #:minimize (optimize-graph QUERY G)
   #:guarantee (check-graph QUERY G)))

(write-solution OUTPUT-PATH QUERY (rosette-sol->solution sol))

