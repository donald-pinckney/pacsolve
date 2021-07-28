#lang racket

(require json)
(require racket/pretty)
(require "query.rkt")
(require "function-dsl.rkt")

(provide read-input-query)


(define (parse-version j) (version (hash-ref j 'major) (hash-ref j 'minor) (hash-ref j 'bug)))
(define (parse-constraint j)
  (define keys (hash-keys j))
  (define k (list-ref keys 0))
  (define data (hash-ref j k))
  (match k
    ['exactly (constraint-exactly (parse-version data))]
    ['wildcardMajor (constraint-wildcardMajor)]
    [else (error "Unknown type of constraint" k)]))

(define (parse-dependency j) (dep (hash-ref j 'packageToDependOn) (parse-constraint (hash-ref j 'constraint))))
(define (parse-dependencies j) (map parse-dependency j))
(define (parse-package-version j) (cons (parse-version (hash-ref j 'version)) (parse-dependencies (hash-ref j 'dependencies))))
(define (parse-package j) (cons (hash-ref j 'package) (vector->immutable-vector (list->vector (map parse-package-version (hash-ref j 'versions))))))
(define (parse-registry j) (vector->immutable-vector (list->vector (map parse-package j))))


(define (make-registry-package-hash reg-vec)
  (define h (make-hash))
  (for-each
   (lambda (p-idx) (hash-set! h (car (vector-ref reg-vec p-idx)) p-idx))
   (range (vector-length reg-vec)))
  h)

(define (make-version-hash vers-vec)
  (define h (make-hash))
  (for-each
   (lambda (v-idx) (hash-set! h (car (vector-ref vers-vec v-idx)) v-idx))
   (range (vector-length vers-vec)))
  h)

(define (make-registry-version-hashes reg-vec)
  (list->vector (map (lambda (p-idx) (make-version-hash (cdr (vector-ref reg-vec p-idx)))) (range (vector-length reg-vec)))))


(define (check-supported-consistency s)
  (if (member s (list "pip" "npm")) #t (error "Unsupported consistency relation")))

(define (check-supported-min-criteria s)
  (if (member s (list "graph-num-vertices")) #t (error "Unsupported minimization criteria")))

(define (parse-options j) 
  (define consis (hash-ref j 'consistency))
  (define crit (hash-ref j 'minimization-criteria))

  (check-supported-consistency consis)
  (map check-supported-min-criteria crit)

  (options
    (hash-ref j 'max-duplicates)
    consis
    (hash-ref j 'check-acyclic)
    crit))

(define (parse-functions fns)
  (define parsed-fns-list (hash-map fns (lambda (name def) (cons name (parse-function def)))))
  (make-hash parsed-fns-list))

(define (read-input-query path)
  (with-input-from-file path (lambda ()
    (define j (read-json))
    (define reg (parse-registry (hash-ref j 'registry)))
    (define c-deps (parse-dependencies (hash-ref j 'context_dependencies)))
    (define options (parse-options (hash-ref j 'options)))
    (define functions-hash (parse-functions (hash-ref j 'functions)))
    ; (pretty-display functions)

    ; (pretty-display 
    ;   (eval-dsl-function
    ;     (make-hash) 
    ;     (hash-ref functions 'constraintInterpretation) 
    ;     (list (make-hash (list (cons 'exactly (make-hash (list (cons 'major 1) (cons 'minor 2) (cons 'bug 3)))) )))))

    (query 
      (registry 
        reg 
        (make-registry-package-hash reg) 
        (make-registry-version-hashes reg)) 
      c-deps
      options
      (functions 
        (hash-ref functions-hash 'versionType)
        (hash-ref functions-hash 'consistency)
        (hash-ref functions-hash 'constraintInterpretation))))))


