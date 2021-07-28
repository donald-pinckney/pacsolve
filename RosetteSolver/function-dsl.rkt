#lang racket

(provide parse-function)
(provide eval-dsl-function)

;; ComplexExpr
(struct LetExpr (varName bindValue rest) #:transparent)
(struct LambdaExpr (param body) #:transparent) ; body must be a SimpleExpr
(struct CallExpr (name args) #:transparent)

;; SimpleExpr
(struct VarExpr (varName) #:transparent)
(struct ConstExpr (value) #:transparent)
(struct PrimitiveOpExpr (op args) #:transparent)

;; Pattern
(struct WildcardPattern () #:transparent)
(struct ConstPattern (value) #:transparent)
(struct BindingPattern (name) #:transparent)
(struct DictionaryPattern (namesPatternsHash) #:transparent)
(struct VectorPattern (patterns) #:transparent)

;; FunctionRule
(struct FunctionRule (patterns rhs) #:transparent)

;; FunctionDef
(struct FunctionDef (numParams rules) #:transparent)


(require racket/hash)

(define (try-merge-bindings b1 b2)
  (hash-union! b1 b2)
  b1)

(define (hash-match patHash argHash)
  (if 
    (and (hash-keys-subset? patHash argHash) (hash-keys-subset? argHash patHash))
    (let* ([keys (hash-keys patHash)]
           [patterns (map (lambda (k) (hash-ref patHash k)) keys)]
           [args (map (lambda (k) (hash-ref argHash k)) keys)]) 
      (check-match patterns args))
    #f))

(define (vector-match patVec argVec)
  (if 
    (= (vector-length patVec) (vector-length argVec))
    (check-match (vector->list patVec) (vector->list argVec))
    #f))

(define (pattern-match pat arg)
  (match pat
    [(WildcardPattern) (make-hash)]
    [(ConstPattern v) (if (equal? v arg) (make-hash) #f)]
    [(BindingPattern name) (make-hash (list (cons name arg)))]
    [(DictionaryPattern subpats) (if (hash? arg) (hash-match subpats arg) #f)]
    [(VectorPattern subpats) (if (vector? arg) (vector-match subpats arg) #f)]))

(define (check-match patterns args)
  (foldl
    (lambda (pat arg bindings)
      (match bindings
        [#f #f]
        [oldBindings 
          (match (pattern-match pat arg)
            [#f #f]
            [newBindings (try-merge-bindings oldBindings newBindings)])]))
      
    (make-hash)
    patterns args))


(define (var-lookup bindings v)
  (match (hash-ref bindings v #f)
    [#f (error "No binding for variable: " v)]
    [val val]))

(define (eval-primitive primitives op args)
  (define fn (hash-ref primitives op))
  (apply fn args))

(define (dsl-eval primitives fns bindings e)

  (match e
    [(VarExpr v) 
      (var-lookup bindings v)]

    [(ConstExpr c) 
      c]

    [(PrimitiveOpExpr op args)
      (let ([evaled-args (map (lambda (arg) (dsl-eval primitives fns bindings arg)) args)])
        (eval-primitive primitives op evaled-args))]

    [(LetExpr varName binding body)
      (let ([evaled-binding (dsl-eval primitives fns bindings binding)])
        (dsl-eval primitives fns (hash-set bindings varName evaled-binding) body))]

    [(CallExpr f args) 
      (let ([evaled-args (map (lambda (arg) (dsl-eval primitives fns bindings arg)) args)])
        (eval-dsl-function primitives fns f evaled-args))]
    
    [(LambdaExpr param body) 
      (lambda (rParam)
        (display "\nInside lambda:\n")
        (display rParam)
        (display "\n")
        (display bindings)
        (display "\n")
        (print param)
        (display "\n")
        (print (hash-set bindings param rParam))
        (display "\n")
        (print body)
        (display "\n")
        ; (display )
        (dsl-eval primitives fns (hash-set bindings param rParam) body))]))

(define (try-eval-rules primitives fns rules args)
  (match rules
    [(cons r moreRules) 
      (match (check-match (FunctionRule-patterns r) args)
        [#f (try-eval-rules primitives fns moreRules args)]
        [bindings (dsl-eval primitives fns (make-immutable-hash (hash->list bindings)) (FunctionRule-rhs r))])]
    [(list) (error "No matching clauses")]))

(define (eval-dsl-function-impl primitives fns f args)
  (if 
    (= (length args) (FunctionDef-numParams f))
    (try-eval-rules primitives fns (FunctionDef-rules f) args)
    (error "Incorrect number of arguments")))

(define (eval-dsl-function primitives fns f args)
  (eval-dsl-function-impl primitives fns (hash-ref fns f) args))


(define (get-class-data j)
  (define keys (hash-keys j))
  (define k (list-ref keys 0))
  (define data (hash-ref j k))
  (cons k data))

(define (unwrap-class j class)
  (define keys (hash-keys j))
  (define k (list-ref keys 0))
  (define data (hash-ref j k))
  (if (and (equal? k class) (= 1 (length keys))) data (error "failed to unwrap correct class")))

  
(define (parse-simple-expr j)
  (match (get-class-data j)
    [(cons 'VarExpr (hash-table ('varName varName))) (VarExpr varName)]
    [(cons 'ConstExpr (hash-table ('value value))) (ConstExpr value)]
    [(cons 'LetExpr (hash-table ('varName varName) ('bindValue bindValue) ('rest theRest)))
      (LetExpr varName (parse-simple-expr bindValue) (parse-simple-expr theRest))]
    [(cons 'PrimitiveOpExpr (hash-table ('op op) ('args args))) 
      (PrimitiveOpExpr op (map parse-simple-expr args))]
    [(cons 'LambdaExpr (hash-table ('param param) ('body body)))
      (LambdaExpr param (parse-simple-expr body))]
    [else (error "Expected simple expr")]))

(define (parse-complex-expr j)
  (match (get-class-data j)
    [(cons 'VarExpr (hash-table ('varName varName))) (VarExpr varName)]
    [(cons 'ConstExpr (hash-table ('value value))) (ConstExpr value)]
    [(cons 'LetExpr (hash-table ('varName varName) ('bindValue bindValue) ('rest theRest)))
      (LetExpr varName (parse-complex-expr bindValue) (parse-complex-expr theRest))]
    [(cons 'PrimitiveOpExpr (hash-table ('op op) ('args args))) 
      (PrimitiveOpExpr op (map parse-complex-expr args))]
    [(cons 'LambdaExpr (hash-table ('param param) ('body body)))
      (LambdaExpr param (parse-simple-expr body))]
    [(cons 'CallExpr (hash-table ('name name) ('args args)))
      (CallExpr name (map parse-complex-expr args))]))

(define (parse-pattern j)
  (match (get-class-data j)
    [(cons 'DictionaryPattern (hash-table ('namesPatternsDict subpatterns))) 
      (define parsed-subs (hash-map subpatterns (lambda (name pat) (cons name (parse-pattern pat)))))
      (DictionaryPattern (make-hasheq parsed-subs))]
    [(cons 'VectorPattern (hash-table ('patterns subpatterns))) 
      (define parsed-subs (vector-map (lambda (pat) (parse-pattern pat)) (list->vector subpatterns)))
      (VectorPattern parsed-subs)]
    [(cons 'BindingPattern (hash-table ('name name))) (BindingPattern name)]
    [(cons 'ConstPattern (hash-table ('value value))) (ConstPattern value)]
    [(cons 'WildcardPattern _) (WildcardPattern)]))

(define (parse-rule j)
  (define data (unwrap-class j 'FunctionRule))
  (define patterns (map parse-pattern (hash-ref data 'patterns)))
  (define rhs (parse-complex-expr (hash-ref data 'rhs)))
  (FunctionRule patterns rhs))

(define (parse-function j)
  (define data (unwrap-class j 'FunctionDef))
  (define nParams (hash-ref data 'numParams))
  (define rules (map parse-rule (hash-ref data 'rules)))
  (FunctionDef nParams rules))
