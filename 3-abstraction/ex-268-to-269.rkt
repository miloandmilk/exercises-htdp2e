#lang htdp/isl

(require test-engine/racket-tests)

; ### Data Definitions

(define-struct rec [name desc acq-price sales-price])
; A Record is a structure 
;  (make-rec String String Number Number)
; It represents an inventory item with these attributes:
; - Name
; - Description
; - Acquisition price
; - Recommended sales price


; ### Constants

(define 
  sample-lor
  (list
    (make-rec "condoms" "Condoms with holes for better ventilation" 3 8)
    (make-rec "screwdriver" "Useless screwdriver" 10 20)
    (make-rec "hammer" "Nice hammer" 50 80)
    ))


; ### Functions

; [List-of Record] -> [List-of Record]
; Returns a list of records sorted by the difference between
; sales price and acquisition price (descending)
(check-expect 
  (sort-by-profit sample-lor)
  (list (third sample-lor) (second sample-lor) (first sample-lor))
  )
(define (sort-by-profit lor)
  (local
    (; Record Record -> Boolean
     ; Compares two records
     (define (comp a b) 
       (> (profit a) (profit b))
       )
     
     ; Record -> Number
     ; Returns the difference between the sales and the
     ; acquisition price
     (define (profit rec)
       (- (rec-sales-price rec) (rec-acq-price rec))
       ))

    ; -- IN --
    (sort lor comp)
    ))


; [List-of Record] Number -> [List-of Record]
; Given a list of Records, it returns another list of record
; with those of which price was in [0, max-price)
(check-expect (eliminate-expensive sample-lor 2) '())
(check-expect 
  (eliminate-expensive sample-lor 25) 
  (list (first sample-lor) (second sample-lor))
  )
(define (eliminate-expensive lor max-price)
  (local
    (; Record -> Boolean
     ; Returns whether the sales price is acceptable
     ; i.e. within limits
     (define (acceptable? rec)
       (< (rec-sales-price rec) max-price)
       ))

    ; -- IN --
    (filter acceptable? lor)
    ))


; String [List-of Record] -> [List-of Record]
; Given a name of product and a list of records,
; it returns a new list with products that do not match
; the passed name
(check-expect (recall "lol" sample-lor) sample-lor)
(check-expect 
  (recall "hammer" sample-lor) 
  (list (first sample-lor) (second sample-lor))
  )
(define (recall ty lor)
  (local
    (; Record -> Boolean
     ; Returns whether the record should be included in 
     ; the result
     (define (good? rec)
       (not (string=? (rec-name rec) ty))
       ))
    
    ; -- IN --
    (filter good? lor)
    ))


; [List-of String] [List-of String] -> [List-of String]
; Given two lists of strings, it returns a new list
; with the elements of the second one that are also in the 
; first one
(check-expect (selection '("lol" "yeah") '("lol" "troll")) '("lol"))
(check-expect (selection '("lol" "yeah") '("paco" "troll")) '())
(define (selection lon1 lon2)
  (local
    (; String -> Boolean
     (define (good? str)
       (member str lon1)
       ))

    ; -- IN --
    (filter good? lon2)
    ))

(test)

