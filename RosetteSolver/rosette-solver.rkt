#lang rosette

; (current-bitwidth 18) ; 32


(define z3-add-model-option (getenv "Z3_ADD_MODEL_OPTION"))
(display z3-add-model-option)


(define z3-path (getenv "Z3_ABS_PATH"))
(display z3-path)

(require rosette/solver/smt/z3)

(cond
  [(and z3-path z3-add-model-option) 
    (current-solver (z3 
      #:path z3-path
      #:options (hash ':model.user_functions "false")))]
  [z3-path (current-solver (z3 #:path z3-path))]
  [z3-add-model-option (current-solver (z3 #:options (hash ':model.user_functions "false")))]
  [else (void)])

(define z3-debug-dir (getenv "Z3_DEBUG"))
(if z3-debug-dir (output-smt z3-debug-dir) (void))


(require "query.rkt")
(require "load-query.rkt")
(require "solution.rkt")
(require "write-solution.rkt")
(require "solution-graph/graph-constraints.rkt")
(require "solution-graph/graph-optimization.rkt")

(require "solution-graph/implementations/impl1.rkt")


(define INPUT-SOURCE
  (if (= 2 (vector-length (current-command-line-arguments)))
      (vector-ref (current-command-line-arguments) 0)
      (error "Incorrect number of command line arguments")))

(define OUTPUT-PATH
  (if (= 2 (vector-length (current-command-line-arguments)))
      (vector-ref (current-command-line-arguments) 1)
      (error "Incorrect number of command line arguments")))

(define QUERY (read-input-query INPUT-SOURCE))
(define IS-PIP (is-pip QUERY))

;;; -------------------------------------------
;;; Actually doing the solve!
;;; -------------------------------------------


(define G (generate-graph QUERY IS-PIP))

(define (rosette-sol->solution sol)
  (if (sat? sol)
    (solution #t (evaluate G sol))
    (solution #f "Failed to solve constraints :(")))

; (pretty-display (optimize-graph QUERY G))

(define sol
  (optimize
   #:minimize (optimize-graph QUERY G)
   #:guarantee (check-graph QUERY G IS-PIP)))

(write-solution OUTPUT-PATH QUERY (rosette-sol->solution sol))

