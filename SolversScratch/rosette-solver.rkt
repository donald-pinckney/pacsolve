#lang rosette

(require rosette/lib/destruct)
(require rosette/lib/angelic)

; A different version of the bounded recursion macro from:
; https://docs.racket-lang.org/rosette-guide/ch_essentials.html?q=constant#%28part._sec~3anotes%29
(define-syntax-rule
  (define-bounded (id param ...) body ...)
  (define id
    (local
      [(define fuel (make-parameter 0)) ; tmp value
       (define (id param ...)
         (assert (>= (fuel) 0) "Out of fuel.")
         (parameterize ([fuel (sub1 (fuel))])
           body ...))]
      (lambda (max-fuel param ...)
        (parameterize ([fuel max-fuel])
          (id param ...))))))

(struct version (major minor bug) #:transparent)
(struct constraint-wildcardMajor () #:transparent)
(struct constraint-exactly (version) #:transparent)
(struct dep (package constraint) #:transparent)


;;; -------------------------------------------
;;; THE PACKAGE REGISTRY & CONTEXT DEPENDENCIES
;;; -------------------------------------------
(define REGISTRY
  (vector-immutable
   (cons "A" (vector-immutable
              (cons (version 1 0 0) (list (dep "B" (constraint-exactly (version 1 0 1)))))))
   (cons "B" (vector-immutable
              (cons (version 1 0 0) (list
                                     (dep "A" (constraint-wildcardMajor))
                                    ))
              (cons (version 1 0 1) (list
                                     ;(dep "A" (constraint-wildcardMajor))
                                    ))
              ))
   (cons "C" (vector-immutable
              (cons (version 1 0 0) (list))))
   (cons "D" (vector-immutable
              (cons (version 1 0 0) (list (dep "C" (constraint-wildcardMajor))))))))
          
(define CONTEXT-DEPS
  (list
   (dep "A" (constraint-wildcardMajor))
   (dep "C" (constraint-wildcardMajor))
  ))

; TODO: Right now this is a really dumb O(n) lookup.
; I could either rewrite the code below to avoid this,
; or I can rewrite this code to be an O(1) lookup with dictionaries.
; But this shouldn't affect the actual constraints, just the generation time.
(define (package-index p)
  (index-where (vector->list REGISTRY) (lambda (p-group) (string=? p (car p-group)))))

(define (registry-get-package-version p v)
  (define p-idx (package-index p))
  (define version-vec (cdr (vector-ref REGISTRY p-idx)))
  (define v-idx (index-where (vector->list version-vec) (lambda (reg-v) (equal? v (car reg-v)))))
  (cdr (vector-ref version-vec v-idx)))

(define (registry-ref p-idx v-idx)
  (vector-ref (cdr (vector-ref REGISTRY p-idx)) v-idx))
  

;;; -------------------------------------------
;;; RESOLUTION GRAPH DATA STRUCTURE
;;; -------------------------------------------

(struct edge (package-idx version-idx node-idx) #:transparent)
(struct node (edges top-order) #:transparent)
(struct version-group (version node-count nodes-list) #:transparent)
(struct package-group (package version-groups-vec) #:transparent)
(struct graph (context-node package-groups-list) #:transparent)

;;; -------------------------------------------
;;; SYMBOLIC GRAPH GENERATION (SKETCHING)
;;; -------------------------------------------

(define-bounded (range-s n)
  (if (> n 0)
      (cons (- n 1) (range-s (- n 1)))
      '()))

(define (fin* n)
  (apply choose* (range n)))

(define (build-list-s* bound len-s f)
  (map (lambda (_) (f)) (range-s bound len-s)))

(define (edge* p-idx max-duplicates)
  (edge
   p-idx
   (fin* (vector-length (cdr (vector-ref REGISTRY p-idx))))
   (fin* max-duplicates)))

(define (node* deps max-duplicates)
  (define-symbolic* ts integer?)
  (node
   (map
    (lambda (dep) (edge* (package-index (dep-package dep)) max-duplicates))
    deps)
   ts))

(define (version-group* version deps max-duplicates)
  (define num-nodes (fin* (add1 max-duplicates)))
  (define nodes
    (build-list-s* max-duplicates num-nodes (lambda () (node* deps max-duplicates))))
  (version-group version num-nodes nodes))

(define (package-group* package max-duplicates)
  (define p-idx (package-index package))
  (define version-specs (vector->list (cdr (vector-ref REGISTRY p-idx))))
  
  (define version-groups
    (map
     (lambda (vers-deps) (version-group* (car vers-deps) (cdr vers-deps) max-duplicates))
     version-specs))

  (package-group package (vector->immutable-vector (list->vector version-groups))))

(define (graph* max-duplicates)
  (define context-node (node* CONTEXT-DEPS max-duplicates))
  (define package-groups
    (map
     (lambda (package-etc) (package-group* (car package-etc) max-duplicates))
     (vector->list REGISTRY)))
 
  (graph context-node package-groups))


;;; ----------------------------------------------
;;; HELPERS FOR TRAVERSING OVER A RESOLUTION GRAPH
;;; ----------------------------------------------


; g : graph
; f : version-group -> package -> ()
(define (for/graph-version-groups g f)
  (for-each (lambda (p-group)
              (for-each (lambda (v-group)
                          (f v-group (package-group-package p-group)))
                        (vector->list (package-group-version-groups-vec p-group))))
            (graph-package-groups-list g)))

; g : graph
; i : acc
; f : version-group -> acc -> acc
(define (foldl/graph-version-groups g i f)
  (define v-groups (flatten (map (lambda (p-group) (vector->list (package-group-version-groups-vec p-group))) (graph-package-groups-list g))))
  (foldl f i v-groups))

; g : graph
; f : edge (out) -> constraint -> package -> version -> node -> ()
(define (for/graph-edges g f)
  (for/graph-version-groups g
    (lambda (v-group package)
      (define deps (registry-get-package-version package (version-group-version v-group)))
      
      (for-each (lambda (node)
                  (for-each (lambda (e dep)
                              (f e (dep-constraint dep) package (version-group-version v-group) node))
                            (node-edges node)
                            deps))
                (version-group-nodes-list v-group))))                   

  (for-each (lambda (e dep)
              (f e (dep-constraint dep) #f #f (graph-context-node g)))
            (node-edges (graph-context-node g))
            CONTEXT-DEPS))



;;; -------------------------------------------
;;; CONSTRAINT GENERATION
;;; -------------------------------------------


;;; *** Constraints part 1: Checking well-formedness (edges have valid indices into node lists), and we have non-negative number of vertices
(define (check-edge-well-formed e g)
  (define p (edge-package-idx e)) ; not symbolic
  (define v (edge-version-idx e)) ; symbolic, already properly bounded
  (define n (edge-node-idx e)) ; symbolic, not propertly bounded by size of destination vector

  (define p-group (list-ref (graph-package-groups-list g) p))
  (define v-group (vector-ref (package-group-version-groups-vec p-group) v))
  
  (assert (<= 0 n))
  (assert (< n (version-group-node-count v-group))))
  
(define (check-version-group-well-formed v-group _package)
  (assert (<= 0 (version-group-node-count v-group))))

(define (check-graph-well-formed g)
  (for/graph-edges g (lambda (e _constraint _p _v _n) (check-edge-well-formed e g)))
  (for/graph-version-groups g check-version-group-well-formed))


;;; *** Constraints part 2: Checking that the graph is a DAG. This check can simply be omitted to allow cyclic graphs
(define (check-graph-acyclic g)
  (assert (= 0 (node-top-order (graph-context-node g))))
  (for/graph-edges g
    (lambda (e c _sp _sv src-node)
      (define dp-idx (edge-package-idx e)) ; not symbolic
      (define dv-idx (edge-version-idx e)) ; symbolic
      (define dn-idx (edge-node-idx e)) ; symbolic

      (define dp-group (list-ref (graph-package-groups-list g) dp-idx))
      (define dv-group (vector-ref (package-group-version-groups-vec dp-group) dv-idx))
      (define dn (list-ref (version-group-nodes-list dv-group) dn-idx)) ; the destination node
      
      (assert (< (node-top-order src-node) (node-top-order dn))))))
                                             
  

;;; *** Constraints part 3: Checking that the graph satisfies all dependency constraints
(define (sat/version-constraint v-s c)
  (destruct c
    [(constraint-wildcardMajor) #t]
    [(constraint-exactly cv) (equal? v-s cv)]))

(define (check-graph-sat-deps g)
  (for/graph-edges g (lambda (e constraint _p _v _n)
    (define dest-version (car (registry-ref (edge-package-idx e) (edge-version-idx e))))
    (assert (sat/version-constraint dest-version constraint)))))


;;; *** Constraints part 4: Checking that the graph contains pairwise consistent versions of the same package, parameterized by relation `r`
(define (check-graph-consistent g r)
  (for-each
   (lambda (p-idx)
     (define v-vec (cdr (vector-ref REGISTRY p-idx)))
     (define n-vers (vector-length v-vec))
     (define p-group (list-ref (graph-package-groups-list g) p-idx)) ; the package group in the graph
     
     (for-each
      (lambda (v1-idx)
        (define v1 (car (vector-ref v-vec v1-idx)))
        (define v1-group (vector-ref (package-group-version-groups-vec p-group) v1-idx)) ; the version group for v1
        (define v1-count (version-group-node-count v1-group))
        
        (for-each
         (lambda (v2-idx)
           (define v2 (car (vector-ref v-vec v2-idx)))
           (define v2-group (vector-ref (package-group-version-groups-vec p-group) v2-idx)) ; the version group for v2
           (define v2-count (version-group-node-count v2-group))

           (if (not (r v1 v2))
               (assert (not (and (< 0 v1-count) (< 0 v2-count))))
               #t))
         (range v1-idx)))
      (range n-vers)))
   (range (vector-length REGISTRY))))
   
(define (consistency/pip v1 v2)
  (equal? v1 v2))

(define (consistency/npm v1 v2)
  #t)

;;; *** Final constraint generation
(define (check-graph g)
  (check-graph-well-formed g)
  (check-graph-acyclic g) ; Just comment this out to allow cyclic graphs
  (check-graph-sat-deps g)
  (check-graph-consistent g consistency/pip))


;;; -------------------------------------------
;;; OPTIMIZATION CRITERIA
;;; -------------------------------------------

(define (graph-num-vertices g)
  (foldl/graph-version-groups
   g
   0
   (lambda (v-group sum)
     (+ sum (version-group-node-count v-group)))))

(define (optimize-graph g)
  ; For now we just minimize the number of vertices
  (list (graph-num-vertices g)))
                                    


;;; -------------------------------------------
;;; Actually doing the solve!
;;; -------------------------------------------

;; Increase this appropriately to allow more duplicate nodes.
;; A value of 1 means that each version will be in the graph either 0 or 1 times (i.e. no duplicates).
(define MAX-DUPLICATES 1) 

(display "Generating...\n")
(define G (graph* MAX-DUPLICATES))
(display "Solving...\n")
(define sol
  (optimize
   #:minimize (optimize-graph G)
   #:guarantee (check-graph G)))
(evaluate G sol)

