;(declare-datatypes (T1 T2 T3) ((Pair3 (mk-pair (first T1) (second T2) (third T3)))))
;(declare-datatypes (T1 T2) ((Pair2 (mk-pair (first T1) (second T2)))))

(declare-datatypes () (
  (Version (mk-semver (major Int) (minor Int) (bug Int)))))

(declare-datatypes () (
  (VersionConstraint 
    (c-exactly (exactly-v Version))
    ;(geq (geq-v Version)) 
    ; ...
    c-wildcardMajor
  )
))


(define-fun version-matches ((v Version) (c VersionConstraint)) Bool
  (ite (is-c-exactly c) (= v (exactly-v c))
  (ite (is-c-wildcardMajor c) true
  false))
)

; Let's say that we have:
; Package A@1.0.0, deps = [B@*]
; Package B@1.0.0, deps = [A@*]
; Package C@1.0.0, deps = []
; Package D@1.0.0, deps = [C@*]

; Solve context deps = [A@*, C@*]

(declare-datatypes () ((Index-a-1.0.0 (mk-Index-a-1.0.0 (idx (_ BitVec 64))))))
(declare-datatypes () ((Index-b-1.0.0 (mk-Index-b-1.0.0 (idx (_ BitVec 64))))))
(declare-datatypes () ((Index-c-1.0.0 (mk-Index-c-1.0.0 (idx (_ BitVec 64))))))
(declare-datatypes () ((Index-d-1.0.0 (mk-Index-d-1.0.0 (idx (_ BitVec 64))))))

(declare-datatypes () ((Edge-A (edge-a-1.0.0 (idx Index-a-1.0.0)))))
(declare-datatypes () ((Edge-B (edge-b-1.0.0 (idx Index-b-1.0.0)))))
(declare-datatypes () ((Edge-C (edge-c-1.0.0 (idx Index-c-1.0.0)))))
(declare-datatypes () ((Edge-D (edge-d-1.0.0 (idx Index-d-1.0.0)))))

(declare-datatypes () ((A-1.0.0-Vertex (mk-a-1.0.0-vertex (a-1.0.0-out0 Edge-B)))))
(declare-datatypes () ((B-1.0.0-Vertex (mk-b-1.0.0-vertex (b-1.0.0-out0 Edge-A)))))
(declare-datatypes () ((C-1.0.0-Vertex (mk-c-1.0.0-vertex))))
(declare-datatypes () ((D-1.0.0-Vertex (mk-d-1.0.0-vertex (d-1.0.0-out0 Edge-C)))))

(define-fun edge-a-version ((e Edge-A)) Version
  (mk-semver 1 0 0)) ; Turn into an ite with more version cases

(define-fun edge-b-version ((e Edge-B)) Version
  (mk-semver 1 0 0)) ; Turn into an ite with more version cases

(define-fun edge-c-version ((e Edge-C)) Version
  (mk-semver 1 0 0)) ; Turn into an ite with more version cases

(define-fun edge-d-version ((e Edge-D)) Version
  (mk-semver 1 0 0)) ; Turn into an ite with more version cases


; Keep track of graph vertices, one array for each package
(declare-const a-1.0.0-vertices (Array Index-a-1.0.0 A-1.0.0-Vertex))
(declare-const b-1.0.0-vertices (Array Index-b-1.0.0 B-1.0.0-Vertex))
(declare-const c-1.0.0-vertices (Array Index-c-1.0.0 C-1.0.0-Vertex))
(declare-const d-1.0.0-vertices (Array Index-d-1.0.0 D-1.0.0-Vertex))



; Outgoing edges for the solve context and ecosystem packages
(declare-const context-edge-0 Edge-A) ; PA
(declare-const context-edge-1 Edge-C) ; PC


(declare-const a-1.0.0-mask (Array Index-a-1.0.0 Bool))
(declare-const b-1.0.0-mask (Array Index-b-1.0.0 Bool))
(declare-const c-1.0.0-mask (Array Index-c-1.0.0 Bool))
(declare-const d-1.0.0-mask (Array Index-d-1.0.0 Bool))


(define-fun check-exist-a ((e Edge-A)) Bool
  (ite (is-edge-a-1.0.0 e) (select a-1.0.0-mask (idx e))
       false)) ; ...

(define-fun check-exist-b ((e Edge-B)) Bool
  (ite (is-edge-b-1.0.0 e) (select b-1.0.0-mask (idx e))
       false)) ; ...

(define-fun check-exist-c ((e Edge-C)) Bool
  (ite (is-edge-c-1.0.0 e) (select c-1.0.0-mask (idx e))
       false)) ; ...

(define-fun check-exist-d ((e Edge-D)) Bool
  (ite (is-edge-d-1.0.0 e) (select d-1.0.0-mask (idx e))
       false)) ; ...

(assert (check-exist-a context-edge-0))
(assert (check-exist-c context-edge-1))

(assert (forall ((idx Index-a-1.0.0))
  (iff 
    (select a-1.0.0-mask idx)
    (check-exist-b (a-1.0.0-out0 (select a-1.0.0-vertices idx))))))

(assert (forall ((idx Index-b-1.0.0))
  (iff 
    (select b-1.0.0-mask idx)
    (check-exist-a (b-1.0.0-out0 (select b-1.0.0-vertices idx))))))

(assert (forall ((idx Index-d-1.0.0))
  (iff 
    (select d-1.0.0-mask idx)
    (check-exist-c (d-1.0.0-out0 (select d-1.0.0-vertices idx))))))

(assert (version-matches (edge-a-version context-edge-0) c-wildcardMajor))
(assert (version-matches (edge-c-version context-edge-1) c-wildcardMajor))

(assert (forall ((idx Index-a-1.0.0))
  (implies 
    (select a-1.0.0-mask idx)
    (version-matches (edge-b-version (a-1.0.0-out0 (select a-1.0.0-vertices idx))) c-wildcardMajor))))

(assert (forall ((idx Index-b-1.0.0))
  (implies 
    (select b-1.0.0-mask idx)
    (version-matches (edge-a-version (b-1.0.0-out0 (select b-1.0.0-vertices idx))) c-wildcardMajor))))

(assert (forall ((idx Index-d-1.0.0))
  (implies 
    (select d-1.0.0-mask idx)
    (version-matches (edge-c-version (d-1.0.0-out0 (select d-1.0.0-vertices idx))) c-wildcardMajor))))


(define-fun bv-pred ((b (_ BitVec 64))) (_ BitVec 64)
  (ite (= b (_ bv0 64)) (_ bv0 64) (bvsub b (_ bv1 64))))

(declare-const max-a-1.0.0 (_ BitVec 64))
(assert (forall ((i Index-a-1.0.0))
  (iff (bvule max-a-1.0.0 (idx i)) (not (select a-1.0.0-mask i)))))

(declare-const max-b-1.0.0 (_ BitVec 64))
(assert (forall ((i Index-b-1.0.0))
  (iff (bvule max-b-1.0.0 (idx i)) (not (select b-1.0.0-mask i)))))

(declare-const max-c-1.0.0 (_ BitVec 64))
(assert (forall ((i Index-c-1.0.0))
  (iff (bvule max-c-1.0.0 (idx i)) (not (select c-1.0.0-mask i)))))

(declare-const max-d-1.0.0 (_ BitVec 64))
(assert (forall ((i Index-d-1.0.0))
  (iff (bvule max-d-1.0.0 (idx i)) (not (select d-1.0.0-mask i)))))


; I would like to minimize the number of duplicate vertices. I.e. I would like to:
; (minimize (bvadd (bv-pred max-a-1.0.0) (bv-pred max-b-1.0.0) (bv-pred max-c-1.0.0) (bv-pred max-d-1.0.0)))
; But that interacts very badly with optimizer

; Instead for now I assert that there are no duplicate vertices
(assert (= max-a-1.0.0 (_ bv1 64)))
(assert (= max-b-1.0.0 (_ bv1 64)))
(assert (= max-c-1.0.0 (_ bv1 64)))
(assert (= max-d-1.0.0 (_ bv1 64)))

(check-sat)
;(get-model)

