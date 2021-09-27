(declare-datatypes () ((Package A B C D)))

; We can bound these Ints by the largest version components, and then use bitvectors
(declare-datatypes () (
  (Version (mk-version (major Int) (minor Int) (bug Int)))))


(declare-datatypes () (
  (PV (mk-pv (package Package) (version Version)))))

(declare-datatypes () (
  (VersionConstraint 
    (c-exactly (exactly-v Version))
    c-wildcardMajor
  )
))

(define-fun version-matches ((v Version) (c VersionConstraint)) Bool
  (ite (is-c-exactly c) (= v (exactly-v c))
  (ite (is-c-wildcardMajor c) true
  false))
)

(define-fun pv-exists ((pv PV)) Bool
  (or
    (= pv (mk-pv A (mk-version 1 0 0)))
    (= pv (mk-pv B (mk-version 1 0 0)))
    (= pv (mk-pv C (mk-version 1 0 0)))
    (= pv (mk-pv D (mk-version 1 0 0)))
  ))


; Let's say that we have:
; Package A@1.0.0, deps = [B@*]
; Package B@1.0.0, deps = [A@*]
; Package C@1.0.0, deps = []
; Package D@1.0.0, deps = [C@*]

; Solve context deps = [A@*, C@*]

; Keep track of which versions of each package have been enabled

(declare-fun required (PV) Bool)
; We can bound these Ints by the number of existing PVs, and use a bitvector instead
(declare-fun top-order (PV) Int) ; may omit

; Outgoing edges for the solve context and ecosystem packages
(declare-const context-edge-0 PV) ; context edge #0 is: A@*
(assert (and
  (pv-exists context-edge-0)
  (= (package context-edge-0) A)
  (version-matches (version context-edge-0) c-wildcardMajor)
  (required context-edge-0)
  ;(> (top-order context-edge-0) 0) ; may omit
))

(declare-const context-edge-1 PV) ; context edge #1 is: C@*
(assert (and
  (pv-exists context-edge-1)
  (= (package context-edge-1) C)
  (version-matches (version context-edge-1) c-wildcardMajor)
  (required context-edge-1)
  ;(> (top-order context-edge-1) 0) ; may omit
))


(declare-const a-1.0.0-edge-0 PV) ; A@1.0.0 edge #0 is: B@*
(assert (=> (required (mk-pv A (mk-version 1 0 0))) 
  (and
    (pv-exists a-1.0.0-edge-0)
    (= (package a-1.0.0-edge-0) B)
    (version-matches (version a-1.0.0-edge-0) c-wildcardMajor)
    (required a-1.0.0-edge-0)
    ;(> (top-order a-1.0.0-edge-0) (top-order (mk-pv A (mk-version 1 0 0)))) ; may omit
)))


(declare-const b-1.0.0-edge-0 PV) ; B@1.0.0 edge #0 is: A@*
(assert (=> (required (mk-pv B (mk-version 1 0 0))) 
  (and
    (pv-exists b-1.0.0-edge-0)
    (= (package b-1.0.0-edge-0) A)
    (version-matches (version b-1.0.0-edge-0) c-wildcardMajor)
    (required b-1.0.0-edge-0)
    ;(> (top-order b-1.0.0-edge-0) (top-order (mk-pv B (mk-version 1 0 0)))) ; may omit
)))


(declare-const d-1.0.0-edge-0 PV) ; D@1.0.0 edge #0 is: C@*
(assert (=> (required (mk-pv D (mk-version 1 0 0))) 
  (and
    (pv-exists d-1.0.0-edge-0)
    (= (package d-1.0.0-edge-0) C)
    (version-matches (version d-1.0.0-edge-0) c-wildcardMajor)
    (required d-1.0.0-edge-0)
    ;(> (top-order d-1.0.0-edge-0) (top-order (mk-pv D (mk-version 1 0 0)))) ; may omit
)))

(minimize (+ 
  (ite (required (mk-pv A (mk-version 1 0 0))) 1 0) 
  (ite (required (mk-pv B (mk-version 1 0 0))) 1 0) 
  (ite (required (mk-pv C (mk-version 1 0 0))) 1 0) 
  (ite (required (mk-pv D (mk-version 1 0 0))) 1 0)
))

(check-sat)
(get-model)
