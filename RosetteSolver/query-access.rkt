#lang rosette

(require "query.rkt")

(provide registry-num-packages)
(provide registry-package-name)
(provide registry-package-cost-values)
(provide registry-num-versions)
(provide registry-ref)
(provide package-index)
(provide version-index)
(provide context-deps)

(define (registry-num-packages query)
  (vector-length (registry-vec (query-registry query))))

(define (registry-package-name query p-idx)
  (parsed-package-package (vector-ref (registry-vec (query-registry query)) p-idx)))

(define (registry-package-cost-values query p-idx)
  (parsed-package-cost-values (vector-ref (registry-vec (query-registry query)) p-idx)))

(define (registry-num-versions query p-idx)
  (vector-length (parsed-package-pv-vec (vector-ref (registry-vec (query-registry query)) p-idx))))

(define (registry-ref query p-idx v-idx)
  (vector-ref (parsed-package-pv-vec (vector-ref (registry-vec (query-registry query)) p-idx)) v-idx))

(define (package-index query p)
  (hash-ref (registry-package-hash (query-registry query)) p))

(define (version-index query p-idx v)
  (hash-ref (vector-ref (registry-version-hashes (query-registry query)) p-idx) v))

(define (context-deps query) (query-context-deps query))


