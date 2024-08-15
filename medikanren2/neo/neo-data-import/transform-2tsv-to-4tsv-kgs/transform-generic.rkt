#lang racket/base

(provide transform-generic)

;; transform-node-and-edge is a pair (transform-node . transform-edge) containing
;; - a transform node function/procedure (transform-node-jsonl or transform-node-tsv)
;; - a transform edge function/procedure (transform-edge-jsonl or transform-edge-tsv)

(define transform-generic
  (lambda (import-directory-path
           export-directory-path
           nodes-import-file-name
           edges-import-file-name
           export-base-file-name
           which-kg
           transform-node-and-edge)
    
    (define node-export-file-name
      (string-append
       export-base-file-name
       ".node.tsv"))
    (define node-props-export-file-name
      (string-append
       export-base-file-name
       ".nodeprop.tsv"))

    (define edge-export-file-name
      (string-append
       export-base-file-name
       ".edge.tsv"))
    (define edge-props-export-file-name
      (string-append
       export-base-file-name
       ".edgeprop.tsv"))
    (define scored-edge-export-file-name
      (string-append
       export-base-file-name
       ".scorededge.tsv"))

        ;; --- nodes ---
    (define nodes-file-import-path
      (string-append
       import-directory-path
       nodes-import-file-name))

    (define node-file-export-path
      (string-append
       export-directory-path
       node-export-file-name))
    (define node-props-file-export-path
      (string-append
       export-directory-path
       node-props-export-file-name))

        ;; --- edges ---
    (define edges-file-import-path
      (string-append
       import-directory-path
       edges-import-file-name))

    (define edge-file-export-path
      (string-append
       export-directory-path
       edge-export-file-name))
    (define edge-props-file-export-path
      (string-append
       export-directory-path
       edge-props-export-file-name))
    (define scored-edge-file-export-path
      (string-append
       export-directory-path
       scored-edge-export-file-name))

    ;; --- precomputed distribution ---
    (define bucket-needed-path
      (string-append
       import-directory-path
       "buckets-needed.tsv"))

    (define start-bucket-numbers-path
      (string-append
       import-directory-path
       "start-bucket-numbers.tsv"))

    (let ((transform-node (car transform-node-and-edge))
          (transform-edge (cdr transform-node-and-edge)))
      (transform-node nodes-file-import-path
                      node-file-export-path
                      node-props-file-export-path
                      which-kg)

      (transform-edge edges-file-import-path
                      bucket-needed-path
                      start-bucket-numbers-path
                      edge-file-export-path
                      edge-props-file-export-path
                      scored-edge-file-export-path
                      which-kg)

    )))