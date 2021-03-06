#lang htdp/isl+

(require test-engine/racket-tests)
(require 2htdp/abstraction)
(require racket/function)
(require racket/list)


; ### Data definitions
(define-struct add [left right])
(define-struct mul [left right])


; A BSL-var-expr is one of:
; - Number
; - Symbol
; - (make-add BSL-var-expr BSL-var-expr)
; - (make-mul BSL-var-expr BSL-var-expr)

; ==================== Exercise 352 ====================

; BSL-var-expr Symbol Number -> BSL-var-expr
; Replaces all occurrences of `sym` with `val` within `ex`
(check-expect (subst 4 'x 0) 4)
(check-expect (subst 'x 'x 0) 0)
(check-expect (subst (make-add 'x 5) 'x 2) (make-add 2 5))
(check-expect 
  (subst (make-mul 'x (make-add 'x 5)) 'x 2)
  (make-mul 2 (make-add 2 5))
  )
(define (subst ex sym val)
  (match
    ex
    [(? number?) ex]
    [(? symbol?) (if (symbol=? ex sym) val ex)]
    [(add l r) (make-add (subst l sym val) (subst r sym val))]
    [(mul l r) (make-mul (subst l sym val) (subst r sym val))]
    ))

; =================== End of exercise ==================




; ==================== Exercise 353 ====================

; BSL-var-expr -> Boolean
; Returns whether `ex` is strictly a numeric expression
; or in other words, whether ex is also a BSL-expr
(check-expect (numeric? 'x) #false)
(check-expect (numeric? 4) #true)
(check-expect (numeric? (make-add 4 5)) #true)
(check-expect (numeric? (make-add 4 'x)) #false)
(check-expect (numeric? (make-mul 4 8)) #true)
(check-expect (numeric? (make-mul 4 (make-add 3 'y))) #false)
(define (numeric? ex)
  (match
    ex
    [(? number?) #true]
    [(add l r) (andmap numeric? (list l r))]
    [(mul l r) (andmap numeric? (list l r))]
    [else #false]
    ))


(define not-numeric? (negate numeric?))

; =================== End of exercise ==================




; ==================== Exercise 354 ====================

; BSL-var-expr -> [Either Number Error]
(check-expect (eval-variable 5) 5)
(check-error (eval-variable 'x))
(check-expect 
  (eval-variable (make-add 2 (make-mul 2 3))) 
  8
  )
(check-error (eval-variable (make-add 2 (make-mul 2 'y))))
(define (eval-variable ex)
  (match
    ex
    [(? not-numeric?) 
     (error "sorry bro, I can handle only numeric expressions")
     ]
    [(? number?) ex]
    [(add l r) (+ (eval-variable l) (eval-variable r))]
    [(mul l r) (* (eval-variable l) (eval-variable r))]
    ))


; An AL (short for association list) is [List-of Association].
; An Association is a list of two items:
;   (cons Symbol (cons Number '())).

(define scope0 '((x 2) (y 3)))

; BSL-var-expr AL -> [Either Number Error]
(check-expect (eval-variable* 5 scope0) 5)
(check-expect (eval-variable* 'x scope0) 2)
(check-error (eval-variable* 'lol scope0))
(check-expect 
  (eval-variable* (make-add 'x (make-mul 'y 5)) scope0) 
  17
  )
(define (eval-variable* ex scope)
  (local
    ((define replaced-ex
       (foldl
         (λ (pair ex) (subst ex (first pair) (second pair)))
         ex
         scope
         )))

     ; -- IN --
     (eval-variable replaced-ex)
     ))

; =================== End of exercise ==================




; ==================== Exercise 354 ====================

; BSL-var-expr AL -> [Either Number Error]
(check-expect (eval-var-lookup 5 scope0) 5)
(check-expect (eval-var-lookup 'x scope0) 2)
(check-error (eval-var-lookup 'lol scope0))
(check-expect 
  (eval-var-lookup (make-add 'x (make-mul 'y 5)) scope0) 
  17
  )
(check-error (eval-var-lookup (make-add 'x (make-mul 'w 5))))
(define (eval-var-lookup ex scope)
  (match
    ex
    [(? symbol?) (resolve-sym ex scope)]

    [(? number?) ex]

    [(add l r) 
     (+ (eval-var-lookup l scope) (eval-var-lookup r scope))
     ]

    [(mul l r) 
     (* (eval-var-lookup l scope) (eval-var-lookup r scope))
     ]))


(define (resolve-sym sym scope)
  (local
    ((define val (assq sym scope)))

    ; -- IN --
    (if 
      (false? val)
      (error "could not find variable in scope")
      (second val))))

; =================== End of exercise ==================




; ==================== Exercise 356 ====================

; ### Data definitions

(define-struct fn-app [fn-name arg])
; A FnApp is a structure:
;   (make-fn-app Symbol BSL-fun-expr)
; i.e.: a data representation of a function
; call with only one argument

; A BSL-fun-expr is one of:
; - Number
; - Symbol
; - (make-add BSL-var-expr BSL-fun-expr)
; - (make-mul BSL-var-expr BSL-fun-expr)
; - (make-fn-app Symbol BSL-fun-expr)
;
; Examples:
; - (k (+ 1 1)) -> 
;     (make-fn-app 'k (make-add 1 1))
;
; - (* 5 (k (+ 1 1))) -> 
;     (make-mul 5 (make-fn-app 'k (make-add 1 1)))
;
; - (* (i 5) (k (+ 1 1))) ->
;     (make-mul
;       (make-fn-app 'i 5)
;       (make-fn-app 'k (make-add 1 1))
;       )

; =================== End of exercise ==================




; ==================== Exercise 357 ====================

(define scope1
  `((x 5)
    (add-one ,add1)
    ))

(define add-5-name 'add-5)
(define add-5-arg-name 'x)
(define add-5-body (make-add 5 add-5-arg-name))

; BSL-fun-expr Symbol Symbol BSL-fun-expr -> Number
; Evaluates `ex` assuming there is only the function 
; `fn-name` in the scope, with the argument `arg`,
; and its body is the expression `body`.
(check-expect (eval-definition1 1 add-5-name add-5-arg-name add-5-body) 1)
(check-expect (eval-definition1 (make-add 2 3) add-5-name add-5-arg-name add-5-body) 5)
(check-expect 
  (eval-definition1 (make-add 2 (make-mul 2 2)) add-5-name add-5-arg-name add-5-body) 
  6
  )
(check-expect 
  (eval-definition1 (make-fn-app add-5-name 10) add-5-name add-5-arg-name add-5-body) 
  15
  )
(check-expect
  (eval-definition1
    (make-mul 10 (make-fn-app add-5-name 7))
    add-5-name
    add-5-arg-name
    add-5-body
    )
  120
  )
(check-error (eval-definition1 'x add-5-name add-5-arg-name add-5-body))
(check-error 
  (eval-definition1 
    (make-fn-app 'x 4)  ; <- function x is not defined in this context
    add-5-name 
    add-5-arg-name 
    add-5-body
    ))
(check-expect
  (eval-definition1
    (make-fn-app add-5-name (make-fn-app add-5-name 7))
    add-5-name
    add-5-arg-name
    add-5-body
    )
  17
  )
; NOTE: this test will end up in infinite recursion
; (check-error 
;   (eval-definition1
;     (make-fn-app add-5-name 5) 
;     add-5-name 
;     add-5-arg-name 
;     (make-fn-app add-5-name 5)
;     ))
(define (eval-definition1 ex fn-name arg-name body)
  (match
    ex
    [(? number?) ex]
    [(? symbol?) (error "no free variables are allowed")]
    [(add l r) 
     (+ 
       (eval-definition1 l fn-name arg-name body) 
       (eval-definition1 r fn-name arg-name body)
       )]
    [(mul l r) 
     (* 
       (eval-definition1 l fn-name arg-name body) 
       (eval-definition1 r fn-name arg-name body)
       )]
    [(fn-app name arg) 
     (cond
       [(not (symbol=? name fn-name)) (error "unknown function")]
       [else
         (eval-definition1 
           ; NOTE: here .v2 is used to allow the body 
           ; of a function to contain fn-app structures
           (subst.v2 
             body 
             arg-name 
             (eval-definition1 arg fn-name arg-name body) 
             )
           fn-name 
           arg-name 
           body
           )])]))


; BSL-fun-expr Symbol Number -> BSL-fun-expr
; Same as subst, but handles fn-app structures
(define (subst.v2 ex sym val)
  (match
    ex
    [(? number?) ex]
    [(? symbol?) (if (symbol=? ex sym) val ex)]
    [(add l r) (make-add (subst.v2 l sym val) (subst.v2 r sym val))]
    [(mul l r) (make-mul (subst.v2 l sym val) (subst.v2 r sym val))]
    [(fn-app fn-name body) 
     (make-fn-app fn-name (subst.v2 body sym val))]
    ))

; =================== End of exercise ==================




; ==================== Exercise 358 ====================

; ### Data Definitions

(define-struct fn-def [name param body])
; a BSL-fun-def is a structure:
;   (make-fn-def Symbol Symbol BSL-fun-expr)
; i.e.: a function called `name` with a unique
;   parameter `param` and with function `body`
;
; Examples:
(define (f x) (+ 3 x))  ; ->
(define f-def (make-fn-def 'f 'x (make-add 3 'x)))

(define (g y) (f (* 2 y))) 
(define g-def (make-fn-def 'g 'y (make-fn-app 'f (make-mul 2 'y))))

(define (h v) (+ (f v) (g v)))
(define h-def
  (make-fn-def 'h 'v (make-add (make-fn-app 'f 'v) (make-fn-app 'g 'v)))
  )

; A BSL-fun-def* is a [List-of BSL-fun-def]
; Can be understood as a definitions area (or scope)
; populated with function definitions.
(define da-fgh (list f-def g-def h-def))

; BSL-fun-def* Symbol -> [Either BSL-fun-def Error]
; Given a definitions-area / scope and a function name
; the proper function def is returned or an error if
; not found
(check-expect (lookup-def da-fgh 'g) g-def)
(define (lookup-def da fn-name)
  (match
    da
    ['() (error "function definition not found")]
    [(cons head tail)
      (if
        (symbol=? (fn-def-name head) fn-name)
        head
        (lookup-def tail fn-name)
        )]))

; =================== End of exercise ==================




; ==================== Exercise 359 ====================

; BSL-fun-expr BSL-fun-def* -> Number
(check-expect (eval-function* 1 da-fgh) 1)
(check-expect (eval-function* (make-mul 3 4) da-fgh) 12)
(check-expect (eval-function* (make-add 3 4) da-fgh) 7)
(check-expect (eval-function* (make-fn-app 'f 3) da-fgh) 6)
(check-expect (eval-function* (make-fn-app 'g 3) da-fgh) 9)
(check-expect (eval-function* (make-fn-app 'h 3) da-fgh) 15)
(define (eval-function* ex da)
  (match
    ex
    [(? number?) ex]
    [(? symbol?) (error "free variable?")]
    [(mul x y) (* (eval-function* x da) (eval-function* y da))]
    [(add x y) (+ (eval-function* x da) (eval-function* y da))]
    [(fn-app fn-name arg)
     (local
       ((define found-fn (lookup-def da fn-name))
        (define evaled-arg (eval-function* arg da))
        (define substituted-body
          (subst.v2 
            (fn-def-body found-fn)
            (fn-def-param found-fn)
            evaled-arg
            )))

       ; -- IN --
       (eval-function* substituted-body da)

       )]))

; =================== End of exercise ==================




; ==================== Exercise 360 ====================

(define-struct const-def [name val])
; A ConstDef is a structure (make-const Symbol Number)
; for example:
(define const-weight (make-const-def 'weight 50))
(define const-height (make-const-def 'height 20))


; A BSL-da-all is one of:
; - '()
; - (cons BSL-fun-def BSL-da-all)
; - (cons ConstDef BSL-da-all)
; For example:
(define da-all
  (append
    (list const-weight const-height)
    da-fgh
    ))

(define ERROR-CONSTANT-NOT-FOUND "could not find constant")

; BSL-da-all Symbol -> [Either ConstDef Error]
(check-expect (lookup-con-def da-all 'height) const-height)
(check-error (lookup-con-def da-all 'lol))
(check-error (lookup-con-def da-all 'f))
(define (lookup-con-def da name)
  (match
    da
    ['() (error ERROR-CONSTANT-NOT-FOUND)]
    [(cons head tail)
      (if
        (and
          (const-def? head)
          (symbol=? (const-def-name head) name)
          )
        head
        (lookup-con-def tail name)
        )]))


(define ERROR-FUNCTION-NOT-FOUND "could not find function")

; BSL-da-all Symbol -> [Either ConstDef Error]
(check-expect (lookup-fun-def da-all 'f) f-def)
(check-error (lookup-fun-def da-all 'lol))
(define (lookup-fun-def da name)
  (match
    da
    ['() (error ERROR-FUNCTION-NOT-FOUND)]
    [(cons head tail)
      (if
        (and
          (fn-def? head)
          (symbol=? (fn-def-name head) name)
          )
        head
        (lookup-fun-def tail name)
        )]))

; =================== End of exercise ==================




; ==================== Exercise 361 ====================

; BSL-fun-expr BSL-da-all -> Number
(check-expect (eval-all 1 da-all) 1)
(check-expect (eval-all (make-mul 3 4) da-all) 12)
(check-expect (eval-all (make-add 3 4) da-all) 7)
(check-expect (eval-all (make-fn-app 'f 3) da-all) 6)
(check-expect (eval-all (make-fn-app 'g 3) da-all) 9)
(check-expect (eval-all (make-fn-app 'h 3) da-all) 15)
(check-expect 
  (eval-all 'height da-all) 
  (const-def-val const-height)
  )
(define (eval-all ex da)
  (match
    ex
    [(? number?) ex]
    [(? symbol?) (const-def-val (lookup-con-def da ex))]
    [(mul x y) (* (eval-all x da) (eval-all y da))]
    [(add x y) (+ (eval-all x da) (eval-all y da))]
    [(fn-app fn-name arg)
     (local
       ((define found-fn (lookup-fun-def da fn-name))
        (define evaled-arg (eval-all arg da))
        (define substituted-body
          (subst.v2 
            (fn-def-body found-fn)
            (fn-def-param found-fn)
            evaled-arg
            )))

       ; -- IN --
       (eval-all substituted-body da)

       )]))

; =================== End of exercise ==================




; ==================== Exercise 362 ====================

; S-expr SL -> Number
(check-expect 
  (interpreter '(+ 1 x) '((define x 5)))
  6
  )
(check-expect 
  (interpreter 
    '(f (+ 1 x)) 
    '((define x 5) 
      (define (f x) (* 2 x)))
    )
  12
  )
(check-error
  (interpreter
    'x
    '()
    )
  ERROR-CONSTANT-NOT-FOUND
  )
(check-error
  (interpreter
    '(f 5)
    '()
    )
  ERROR-FUNCTION-NOT-FOUND
  )
(define (interpreter expr-se defs-se)
  (local
    ((define expr (parse expr-se))
     (define da (map parse defs-se))
     ) 

    ; -- IN --
    (eval-all expr da)
    ))


; S-expr -> BSL-fun-expr
; Generates an BSL-fun-expr from a S-expression, as
; long as it can be parsed. 
(check-expect (parse 45) 45)
(check-expect (parse '(* 3 (+ 3 4))) (make-mul 3 (make-add 3 4)))
(check-error (parse "lol"))
(check-error (parse '(+ 10 5 3)))
(check-expect (parse '(f 5)) (make-fn-app 'f 5))
(check-expect (parse '(f (+ 1 1))) (make-fn-app 'f (make-add 1 1)))
(check-expect (parse '(f (* 1 z))) (make-fn-app 'f (make-mul 1 'z)))
(check-expect (parse '(define some-const 4)) (make-const-def 'some-const 4))
(check-expect (parse '(define some-const z)) (make-const-def 'some-const 'z))
(check-expect (parse '(define (some-fn x) x)) (make-fn-def 'some-fn 'x 'x))
(define (parse s)
  (cond
    [(atom? s) (parse-atom s)]
    [else (parse-sl s)]
    ))
 

(define ERROR-ATOM "unexpected atom")

; SL -> BSL-expr 
(define (parse-sl s)
  (match
    s
    [(cons '+ (cons l (cons r '())))
     (make-add (parse l) (parse r))
     ]

    [(cons '* (cons l (cons r '())))
     (make-mul (parse l) (parse r))
     ]

    [(cons 'define tail) (parse-define tail)]

    [(cons (? symbol?) (cons fn-arg '()))
     (make-fn-app (first s) (parse fn-arg))
     ]

    [else (error "not parseable!")]
    ))


; SL -> [Either BSL-fun-expr Error]
; Parses a "define" SL. The S-expr list MUST NOT contain
; the 'define symbol at the start, just the rest.
(define (parse-define def)
  (match 
    def
    ; NOTE: fn-def must come before const-def, since constant matching 
    ; pattern would absorb functions as well
    [(cons (cons fn-name (cons fn-param '())) (cons fn-body '()))
     (make-fn-def fn-name fn-param (parse fn-body))
     ]

    [(cons const-name (cons const-val '()))
     (make-const-def const-name (parse const-val))
     ]

    [else (error "define expression was neither func nor const")]
    ))


(define ERROR-STRING "Upgrade to premium version to be able to use strings!!!")


; Atom -> BSL-expr 
(define (parse-atom s)
  (cond
    [(number? s) s]
    [(symbol? s) s]
    [(string? s) (error ERROR-STRING)]
    ))


; [X] X -> Boolean
; Atom predicate
(define (atom? x)
  (or (number? x) (string? x) (symbol? x))
  )


; =================== End of exercise ==================

(test)

