#lang rosette

(require rosette/lib/destruct)
(require rosette/lib/angelic)
(require json)


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

(define (parse-version j) (version (hash-ref j 'major) (hash-ref j 'minor) (hash-ref j 'bug)))
(define (parse-constraint j)
  ;(display j)
  (define keys (hash-keys j))
  (assert (= (length keys) 1))
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

(define (read-input path)
  (with-input-from-file path (lambda () (parse-json (read-json)))))



;;; -------------------------------------------
;;; THE PACKAGE REGISTRY & CONTEXT DEPENDENCIES
;;; -------------------------------------------

(define SAMPLE-REGISTRY
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
          
(define SAMPLE-CONTEXT-DEPS
  (list
   (dep "A" (constraint-wildcardMajor))
   (dep "C" (constraint-wildcardMajor))
  ))

(define INPUT-SOURCE
  (if (= 2 (vector-length (current-command-line-arguments)))
      (vector-ref (current-command-line-arguments) 0)
      ;#f
      "RosetteSolver/sample-data/input_sample.json"
      ;"/var/folders/9x/h9vpkyxj3pg0chrllkhfpkzm0000gn/T/tmp06gcelmz"
      ))

(define-values (REGISTRY CONTEXT-DEPS)
  (if (equal? #f INPUT-SOURCE)
      (values SAMPLE-REGISTRY SAMPLE-CONTEXT-DEPS)
      (read-input INPUT-SOURCE)))

(define (registry-num-packages)
  (vector-length REGISTRY))

(define (registry-package-name p-idx)
  (car (vector-ref REGISTRY p-idx)))

(define (registry-num-versions p-idx)
  (vector-length (cdr (vector-ref REGISTRY p-idx))))

(define (registry-ref p-idx v-idx)
  (vector-ref (cdr (vector-ref REGISTRY p-idx)) v-idx))


(define (make-registry-package-hash)
  (define h (make-hash))
  (for-each
   (lambda (p-idx) (hash-set! h (car (vector-ref REGISTRY p-idx)) p-idx))
   (range (registry-num-packages)))
  h)

(define (make-version-hash vers-vec)
  (define h (make-hash))
  (for-each
   (lambda (v-idx) (hash-set! h (car (vector-ref vers-vec v-idx)) v-idx))
   (range (vector-length vers-vec)))
  h)

(define (make-registry-version-hashes)
  (list->vector (map (lambda (p-idx) (make-version-hash (cdr (vector-ref REGISTRY p-idx)))) (range (registry-num-packages)))))

(define PACKAGE-HASH (make-registry-package-hash))
(define VERSION-HASHES (make-registry-version-hashes))

(define (package-index p)
  (hash-ref PACKAGE-HASH p))

(define (version-index p-idx v)
  (hash-ref (vector-ref VERSION-HASHES p-idx) v))


  

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


(define (range-s-not-bound n)
  (if (> n 0)
      (cons (- n 1) (range-s-not-bound (- n 1)))
      '()))

(define (fin* n)
  (apply choose* (range n)))

(define (build-list-s* bound len-s f)
  (map (lambda (_) (f)) (range-s bound len-s)))

(define (edge* p-idx max-duplicates)
  (edge
   p-idx
   (fin* (registry-num-versions p-idx))
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
  (define version-idxs (range (registry-num-versions p-idx)))
  
  (define version-groups
    (map
     (lambda (version-idx)
       (define version-pair (registry-ref p-idx version-idx))
       (version-group* (car version-pair) (cdr version-pair) max-duplicates))
     version-idxs))

  (package-group package (vector->immutable-vector (list->vector version-groups))))

(define (graph* max-duplicates)
  (define context-node (node* CONTEXT-DEPS max-duplicates))
  (define p-idxs (range (registry-num-packages)))
  (define package-groups
    (map
     (lambda (p-idx) (package-group* (registry-package-name p-idx) max-duplicates))
     p-idxs))
 
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
      (define p-idx (package-index package))
      (define v-idx (version-index p-idx (version-group-version v-group)))

      (define deps (cdr (registry-ref p-idx v-idx)))
      
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
;;; SERIALIZING SOLUTION GRAPH TO JSON
;;; -------------------------------------------


(define (flatten-graph-idx e p-counts v-counts)
  (define p-idx (edge-package-idx e))
  (define v-idx (edge-version-idx e))
  (define n-idx (edge-node-idx e))
  
  (define prev-p-sum (apply + (map (lambda (prev-p-idx) (list-ref p-counts prev-p-idx)) (range p-idx))))
  (define vg-counts (list-ref v-counts p-idx))
  (define prev-v-sum (apply + (map (lambda (prev-v-idx) (list-ref vg-counts prev-v-idx)) (range v-idx))))
  (+ 1 prev-p-sum prev-v-sum n-idx))

(define (version->json v) (make-hash (list (cons 'major (version-major v)) (cons 'minor (version-minor v)) (cons 'bug (version-bug v)))))

(define (resolved-vertex->json p v) (make-hash (list (cons 'type "ResolvedPackageVertex") (cons 'package p) (cons 'version (version->json v)))))

(struct temp-graph-node (vertex-data edge-data) #:transparent)

(define (graph->json g)
  (define context-edges (node-edges (graph-context-node g)))
  (define p-groups (graph-package-groups-list g))
  (define version-counts
    (map
     (lambda (pg)
       (map
        (lambda (vg-idx)
          (define vg (vector-ref (package-group-version-groups-vec pg) vg-idx))
          (version-group-node-count vg))
        (range (vector-length (package-group-version-groups-vec pg)))))
     p-groups))
  (define package-counts (map (lambda (xs) (apply + xs)) version-counts))

  (define vertices-and-edges-flattened 
    (flatten
     (map
      (lambda (pg)
        (define p (package-group-package pg))
        (map
         (lambda (vg-idx)
           (define vg (vector-ref (package-group-version-groups-vec pg) vg-idx))
           (define v (version-group-version vg))
           (map
            (lambda (n)
              (temp-graph-node (resolved-vertex->json p v) (node-edges n)))
            (version-group-nodes-list vg)))
         (range (vector-length (package-group-version-groups-vec pg)))))
      p-groups)))

  (define vertices
    (cons (make-hash (list (cons 'type "RootContextVertex")))
          (map (lambda (pr) (temp-graph-node-vertex-data pr)) vertices-and-edges-flattened)))

  (define edge-data
    (cons
     context-edges
     (map (lambda (pr) (temp-graph-node-edge-data pr)) vertices-and-edges-flattened)))

  (define edge-flat-indices
    (map
     (lambda (edges)
       (map
        (lambda (e)
          (flatten-graph-idx e package-counts version-counts))
        edges))
     edge-data))

  (make-hash (list (cons 'vertices vertices) (cons 'out_edge_array edge-flat-indices) (cons 'context_vertex 0))))

(define (sol->json g sol)
  (if (sat? sol)
      (make-hash (list (cons 'success #t) (cons 'graph (graph->json (evaluate g sol)))))
      (make-hash (list (cons 'success #f) (cons 'error "Failed to solve constraints :(")))))





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
     (define n-vers (registry-num-versions p-idx))
     (define p-group (list-ref (graph-package-groups-list g) p-idx)) ; the package group in the graph
     
     (for-each
      (lambda (v1-idx)
        (define v1 (car (registry-ref p-idx v1-idx)))
        (define v1-group (vector-ref (package-group-version-groups-vec p-group) v1-idx)) ; the version group for v1
        (define v1-count (version-group-node-count v1-group))
        
        (for-each
         (lambda (v2-idx)
           (define v2 (car (registry-ref p-idx v2-idx)))
           (define v2-group (vector-ref (package-group-version-groups-vec p-group) v2-idx)) ; the version group for v2
           (define v2-count (version-group-node-count v2-group))

           (if (not (r v1 v2)) ; v1 and v2 are concrete
               (assert (not (and (< 0 v1-count) (< 0 v2-count)))) ; v1-count and v2-count are symbolic
               #t))
         (range v1-idx)))
      (range n-vers)))
   (range (registry-num-packages))))
   
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
  (list
   (graph-num-vertices g)))
                                    


;;; -------------------------------------------
;;; Actually doing the solve!
;;; -------------------------------------------

;; Increase this appropriately to allow more duplicate nodes.
;; A value of 1 means that each version will be in the graph either 0 or 1 times (i.e. no duplicates).
(define MAX-DUPLICATES 1) 

;(display "Generating...\n")
(define G (graph* MAX-DUPLICATES))
;(display "Solving...\n")
(define sol
  (optimize
   #:minimize (optimize-graph G)
   #:guarantee (check-graph G)))
;(evaluate G sol)

;(display "\n")

;(sol->json G sol)

(define OUTPUT-PATH
  (if (= 2 (vector-length (current-command-line-arguments)))
      (vector-ref (current-command-line-arguments) 1)
      "RosetteSolver/sample-data/output_sample.json"
      ))
(define (write-output path j)
  (with-output-to-file path (lambda () (write-json j)) #:exists 'replace))

(write-output OUTPUT-PATH (sol->json G sol))

