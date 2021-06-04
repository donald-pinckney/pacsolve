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

(declare-datatypes () ((PA A@1.0.0)))
(declare-datatypes () ((PB B@1.0.0)))
(declare-datatypes () ((PC C@1.0.0)))
(declare-datatypes () ((PD D@1.0.0)))

(define-fun to-version-PA ((p PA)) Version
  (ite (= p A@1.0.0) (mk-semver 1 0 0)
  (mk-semver 0 0 0)))

(define-fun to-version-PB ((p PB)) Version
  (ite (= p B@1.0.0) (mk-semver 1 0 0)
  (mk-semver 0 0 0)))

(define-fun to-version-PC ((p PC)) Version
  (ite (= p C@1.0.0) (mk-semver 1 0 0)
  (mk-semver 0 0 0)))

(define-fun to-version-PD ((p PD)) Version
  (ite (= p D@1.0.0) (mk-semver 1 0 0)
  (mk-semver 0 0 0)))

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

; Keep track of which versions of each package have been enabled
(declare-const a-versions (Array Version Bool))
(declare-const b-versions (Array Version Bool))
(declare-const c-versions (Array Version Bool))
(declare-const d-versions (Array Version Bool))

; Outgoing edges for the solve context and ecosystem packages
(declare-const context-edge-0 PA)
(declare-const context-edge-1 PC)

(declare-const a-1.0.0-edge-0 PB)

(declare-const b-1.0.0-edge-0 PA)

(declare-const d-1.0.0-edge-0 PC)

; Keeping sets updated with edges
(assert (implies (= context-edge-0 A@1.0.0) (select a-versions (mk-semver 1 0 0))))
(assert (implies (= context-edge-1 C@1.0.0) (select c-versions (mk-semver 1 0 0))))

(assert (implies (and (select a-versions (mk-semver 1 0 0)) (= a-1.0.0-edge-0 B@1.0.0)) (select b-versions (mk-semver 1 0 0))))

(assert (implies (and (select b-versions (mk-semver 1 0 0)) (= b-1.0.0-edge-0 A@1.0.0)) (select a-versions (mk-semver 1 0 0))))

(assert (implies (and (select d-versions (mk-semver 1 0 0)) (= d-1.0.0-edge-0 C@1.0.0)) (select c-versions (mk-semver 1 0 0))))


; Edge matching requirements
(assert (implies (select a-versions (mk-semver 1 0 0)) (version-matches (to-version-PB a-1.0.0-edge-0) c-wildcardMajor)))
(assert (implies (select b-versions (mk-semver 1 0 0)) (version-matches (to-version-PA b-1.0.0-edge-0) c-wildcardMajor)))
(assert (implies (select d-versions (mk-semver 1 0 0)) (version-matches (to-version-PC d-1.0.0-edge-0) c-wildcardMajor)))

(assert (version-matches (to-version-PA context-edge-0) c-wildcardMajor))
(assert (version-matches (to-version-PC context-edge-1) c-wildcardMajor))


(check-sat)
(get-model)
