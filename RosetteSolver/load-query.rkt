#lang racket

(require json)
(require "query.rkt")
(require "function-dsl.rkt")
(require "dsl-primitives-concrete.rkt")
(require "dsl-primitives-symbolic.rkt")

(provide read-input-query)


(define (parse-version fns j)
  (eval-dsl-function
    DSL-PRIMITIVES-CONCRETE
    fns
    "versionDeserialize"
    (list j)))
  
(define (parse-constraint fns j)
  (eval-dsl-function
    DSL-PRIMITIVES-SYMBOLIC
    fns
    "constraintInterpretation"
    (list j)))

(define (parse-dependency fns j) 
  (dep 
    (hash-ref j 'packageToDependOn) 
    (parse-constraint fns (hash-ref j 'constraint))))
(define (parse-dependencies fns j) (map (lambda (x) (parse-dependency fns x)) j))


(define (parse-package-version fns j) 
  (parsed-package-version
    (parse-version fns (hash-ref j 'version)) 
    (hash-ref j 'cost_values)
    (parse-dependencies fns (hash-ref j 'dependencies))))


(define (parse-package fns j) 
  (parsed-package 
    (hash-ref j 'package) 
    (hash-ref j 'cost_values)
    (vector->immutable-vector (list->vector (map (lambda (x) (parse-package-version fns x)) (hash-ref j 'versions))))))

(define (parse-registry fns j) 
  (vector->immutable-vector (list->vector (map (lambda (x) (parse-package fns x)) j))))


(define (make-registry-package-hash reg-vec)
  (define h (make-hash))
  (for-each
   (lambda (p-idx) (hash-set! h (parsed-package-package (vector-ref reg-vec p-idx)) p-idx))
   (range (vector-length reg-vec)))
  h)

(define (make-version-hash vers-vec)
  (define h (make-hash))
  (for-each
   (lambda (v-idx) (hash-set! h (parsed-package-version-version (vector-ref vers-vec v-idx)) v-idx))
   (range (vector-length vers-vec)))
  h)

(define (make-registry-version-hashes reg-vec)
  (list->vector 
    (map 
      (lambda (p-idx) (make-version-hash (parsed-package-pv-vec (vector-ref reg-vec p-idx)))) 
      (range (vector-length reg-vec)))))

(define (parse-options j) 
  (define min_objective_names (hash-ref j 'minimization_criteria))

  (options
    (hash-ref j 'check_acyclic)
    min_objective_names))

(define (parse-functions fns)
  (define parsed-fns-list (hash-map fns (lambda (name def) (cons name (parse-function def)))))
  (make-hash parsed-fns-list))

(define (read-input-query path)
  (with-input-from-file path (lambda ()
    (define j (read-json))

    (define fns-tmp (parse-functions (hash-ref j 'functions)))

    (define fns (make-immutable-hash 
      (map 
        (lambda (pair) (cons (symbol->string (car pair)) (cdr pair)))
        (hash->list fns-tmp))))

    (define reg (parse-registry fns (hash-ref j 'registry)))
    (define c-deps (parse-dependencies fns (hash-ref j 'context_dependencies)))
    (define options (parse-options (hash-ref j 'options)))

    (query 
      (registry 
        reg 
        (make-registry-package-hash reg) 
        (make-registry-version-hashes reg)) 
      c-deps
      options
      fns))))

