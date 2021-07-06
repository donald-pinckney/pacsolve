#lang racket

(provide (struct-out solution))

(struct solution (success graphOrMessage) #:transparent)