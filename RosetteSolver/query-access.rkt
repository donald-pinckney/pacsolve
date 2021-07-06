#lang rosette

(require "query.rkt")
(require "load-query.rkt")


(define INPUT-SOURCE
  (if (= 2 (vector-length (current-command-line-arguments)))
      (vector-ref (current-command-line-arguments) 0)
      (error "Incorrect number of command line arguments")))

(define QUERY (read-input-query INPUT-SOURCE))

(provide REGISTRY-NUM-PACKAGES)
(provide registry-package-name)
(provide registry-num-versions)
(provide registry-ref)
(provide package-index)
(provide version-index)
(provide CONTEXT-DEPS)

(define REGISTRY-NUM-PACKAGES
  (vector-length (registry-vec (query-registry QUERY))))

(define (registry-package-name p-idx)
  (car (vector-ref (registry-vec (query-registry QUERY)) p-idx)))

(define (registry-num-versions p-idx)
  (vector-length (cdr (vector-ref (registry-vec (query-registry QUERY)) p-idx))))

(define (registry-ref p-idx v-idx)
  (vector-ref (cdr (vector-ref (registry-vec (query-registry QUERY)) p-idx)) v-idx))

(define (package-index p)
  (hash-ref (registry-package-hash (query-registry QUERY)) p))

(define (version-index p-idx v)
  (hash-ref (vector-ref (registry-version-hashes (query-registry QUERY)) p-idx) v))

(define CONTEXT-DEPS (query-context-deps QUERY))


