#lang racket/base
(provide curie->synonyms curies->synonyms)
(require
  "../../../medikanren2/dbk/dbk/data.rkt"
  "../../../medikanren2/dbk/dbk/enumerator.rkt"
  racket/runtime-path
  racket/set)

(define (curie->synonyms curie) (curies->synonyms (list curie)))

(define (curies->synonyms curies)
  (define (ids->dict ids)
    (define vec.ids (list->vector (sort (set->list ids) <)))
    (dict:ordered (column:vector vec.ids) (column:const '()) 0 (vector-length vec.ids)))
  (define (step new)
    (define (step/dict dict.edge.Y.X) (enumerator->rlist
                                        (lambda (yield)
                                          ((merge-join dict.new dict.edge.Y.X)
                                           (lambda (id.curie _ dict.edge.Y)
                                             ((dict.edge.Y 'enumerator) yield))))))
    (define dict.new (ids->dict new))
    (list->set (append (step/dict dict.edge.object.subject)
                       (step/dict dict.edge.subject.object))))
  (define ids.final (set-fixed-point (list->set (strings->ids curies)) step))
  (enumerator->list
    (lambda (yield)
      ((merge-join (ids->dict ids.final) dict.id=>string)
       (lambda (_ __ curie) (yield curie))))))

;;;;;;;;;;;;;;;
;; Utilities ;;
;;;;;;;;;;;;;;;
(define (set-fixed-point xs.initial step)
  (let loop ((current (set))
             (next    xs.initial))
    (let ((new (set-subtract next current)))
      (if (set-empty? new)
        current
        (loop (set-union current new)
              (step      new))))))

(define (dict-select d key) (d 'ref key (lambda (v) v) (lambda () (error "dict ref failed" key))))

;; TODO: build small in-memory relations more easily
(define (strings->dict strs)
  (define vec.strs  (list->vector (sort (set->list (list->set strs)) string<?)))
  (define dict.strs (dict:ordered (column:vector vec.strs) (column:const '()) 0 (vector-length vec.strs)))
  (define vec.ids   (enumerator->vector
                      (lambda (yield)
                        ((merge-join dict.strs dict.string=>id)
                         (lambda (__ ___ id) (yield id))))))
  (dict:ordered (column:vector vec.ids) (column:const '()) 0 (vector-length vec.ids)))

(define (strings->ids strs) (enumerator->rlist ((strings->dict strs) 'enumerator)))

(define-runtime-path path.here ".")
(define db     (database (path->string (build-path path.here "kgx-synonym.db"))))
(define r.edge (database-relation db '(kgx-synonym edge)))

(define domain-dicts                 (relation-domain-dicts r.edge))
(define dict.string=>id              (car (hash-ref (car domain-dicts) 'text)))
(define dict.id=>string              (car (hash-ref (cdr domain-dicts) 'text)))

(define dict.edge.object.subject (relation-index-dict r.edge '(subject object)))
(define dict.edge.subject.object (relation-index-dict r.edge '(object subject)))
