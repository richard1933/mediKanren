;; Custodian, thread, channel experiments

;; This version *does not* shut down the infinite loop!

(define *n* 0)
(define *cust* #f)

(printf "*** 1 *n*: ~s\n" *n*)
(define t1-thunk
  (lambda ()
    (define t1-thunk-cust (make-custodian))
    (set! *cust* t1-thunk-cust)
    (parameterize ((current-custodian t1-thunk-cust))
      (let loop ()
        (set! *n* (add1 *n*))
        (loop)))))

(printf "*** 2 *n*: ~s\n" *n*)
(define t1
  (thread t1-thunk))

(printf "*** 3 *n*: ~s\n" *n*)
(sleep 1)
(printf "*** 4 *n*: ~s\n" *n*)
(custodian-shutdown-all *cust*)
(printf "*** 5 *n*: ~s\n" *n*)
(sleep 1)
(printf "*** 6 *n*: ~s\n" *n*)