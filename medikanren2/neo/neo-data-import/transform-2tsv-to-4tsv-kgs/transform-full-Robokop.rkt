#lang racket

(require "transform-generic.rkt"
         "transform-edge-jsonl.rkt"
         json
         "../../neo-reasoning/neo-biolink-reasoning-low-level.rkt")

(define transform-node-jsonl
  (lambda (nodes-file-import-path
           node-file-export-path
           node-props-file-export-path
           which-kg)

    (printf "transform-node-jsonl called\n")
    (printf "input nodes jsonl: ~s\n" nodes-file-import-path)
    (printf "output node tsv: ~s\n" node-file-export-path)
    (printf "output node props tsv: ~s\n" node-props-file-export-path)
    
    (define node-out
      (open-output-file node-file-export-path))
    (fprintf node-out ":ID\n")
    (define node-props-out
      (open-output-file node-props-file-export-path))
    (fprintf node-props-out ":ID\tpropname\tvalue\n")

    (define nodes-in
      (open-input-file nodes-file-import-path))

    (let loop ((i 0)
               (seen-nodes (set))
               (line-json (read-json nodes-in)))
      (when (zero? (modulo i 100000))
        (printf "processing nodes line ~s\n" i))

      (cond
        [(eof-object? line-json)
         (close-input-port nodes-in)
         (close-output-port node-out)
         (close-output-port node-props-out)
         (printf "finished processing nodes\n\n")]
        [else
         (let ((id (hash-ref line-json 'id #f)))
           (if id
               (begin
                 (when (set-member? seen-nodes id)
                   (error 'make-kg-node (format "already seen node: ~a" id)))
                 (fprintf node-out "~a\n" id)
                 (let* ((name (hash-ref line-json 'name "N/A"))
                        (categories (hash-ref line-json 'category #f))
                        (categories-smallest-nonmixin (and categories
                                                           (list? categories)
                                                           (get-smallest-nonmixin-class* categories))))
                   (fprintf node-props-out "~a\tname\t~a\n" id name)
                   (cond
                     ((and categories-smallest-nonmixin
                           (not (null? categories-smallest-nonmixin)))
                      (for-each
                       (lambda (c)
                         (fprintf node-props-out "~a\tcategory\t~a\n" id c))
                       categories-smallest-nonmixin))
                     ((and categories-smallest-nonmixin
                           (null? categories-smallest-nonmixin))
                      (let ((categories-samllest (find-leaf-classes categories)))
                        (for-each
                         (lambda (c)
                           (fprintf node-props-out "~a\tcategory\t~a\n" id c))
                         categories-samllest)))
                     ((and categories (string? categories))
                      (fprintf node-props-out "~a\tcategory\t~a\n" id categories))
                     (else
                      (printf "unseen format" categories))))
                 (loop
                  (add1 i)
                  (set-add seen-nodes id)
                  (read-json nodes-in)))
               (loop
                (add1 i)
                seen-nodes
                (read-json nodes-in))))]))))

(define BASE "robokop-march-7-2024/")

(transform-generic
 (string-append "../../neo-data/raw_downloads_from_kge_archive/" BASE)
 (string-append "../../neo-data/raw_downloads_from_kge_archive_transformed_to_4tsv/" BASE)
 "nodes.jsonl"
 "edges.jsonl"
 "Robokop"
 'robokop
 (cons transform-node-jsonl transform-edge-jsonl))
