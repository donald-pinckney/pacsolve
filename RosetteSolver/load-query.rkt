#lang racket

(require json)
(require "query.rkt")

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

(define (parse-json j)
  (values
   (parse-registry (hash-ref j 'registry))
   (parse-dependencies (hash-ref j 'context_dependencies))))


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


(define (read-input-query path)
  (with-input-from-file path (lambda ()
    (define-values (reg c-deps) (parse-json (read-json)))
    (query 
      (registry 
        reg 
        (make-registry-package-hash reg) 
        (make-registry-version-hashes reg)) 
      c-deps
      (options
        1
        "pip"
        #t
        (list "graph-num-vertices"))))))


