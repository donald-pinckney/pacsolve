#lang racket

(provide (struct-out version))
(provide (struct-out constraint-wildcardMajor))
(provide (struct-out constraint-exactly))
(provide (struct-out dep))

(provide (struct-out registry))
(provide (struct-out query))


(struct version (major minor bug) #:transparent)
(struct constraint-wildcardMajor () #:transparent)
(struct constraint-exactly (version) #:transparent)
(struct dep (package constraint) #:transparent)

(struct registry (vec package-hash version-hashes) #:transparent)
(struct query (registry context-deps) #:transparent)




