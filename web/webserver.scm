#!/usr/bin/env guile \
-e main -s
!#
;; Minimal web server can be started from command line. Current routes:
;;
;;    localhost:8080/status.json
;;
;; Note that this is a single blocking thread server - that makes
;; sense to not to overload the local redis instance

(use-modules (json)
             (redis)
             (web server)
             (web request)
             (web response)
             (web uri))

(define (request-path-components request)
  (split-and-decode-uri-path (uri-path (request-uri request))))

(define (get-status-as-json-string-list)
  ;; return a list of strings containing json records
  (let* ((conn (redis-connect))
         (sorted-list (redis-send conn (lrange '("sheepdog_run" 0 1000)))))
    (redis-close conn)
    sorted-list
     ))

(define (get-status-as-single-json-string)
  (string-append "[" (string-join (get-status-as-json-string-list) ",\n") "]"))

(define (get-status-as-scm)
  (let ((js get-status-as-json-string-list))
    (map json-string->scm (get-status-as-json-string-list))))

(define (filter-last-states)
  (let ((l (get-status-as-scm))
        (nlist '()))
    (map (lambda (rec)
           (let* ((tag (string-append (cdr (assoc "host" rec)) (cdr (assoc "command" rec))))
                  (found (assoc tag nlist)))
             (if (not found)
                 (set! nlist (assoc-set! nlist tag #t)))
             (if found
                 #f
                 rec)
             )
           ) l)))

(define (status-line rec)
  (string-append
   (cdr (assoc "time" rec)) "\t"
   (cdr (assoc "err" rec)) "\t"
   (cdr (assoc "host" rec)) "\t"
   (cdr (assoc "tag" rec)) "\t"
   (cdr (assoc "command" rec))
   ))

(define (get-status-as-html)
  (let ((l (filter-last-states)))
    (string-append "<pre>"
                   (string-join (map (lambda (rec)
                                       (if rec
                                           (string-append (status-line rec) "\n")
                                           ""
                                           )) l) "")
                   "</pre>")))

(define (hello-world-handler request body)
  (let ((path (uri-path (request-uri request))))
    (cond
     ((member path (list "/status.json"))
      (values '((content-type . (application/json)))
              (get-status-as-single-json-string)
              ))
     ((member path (list "/status.html"))
      (values '((content-type . (text/html)))
              (get-status-as-html)
              ))
     (else
      (not-found request)))))

(define (not-found request)
  (values (build-response #:code 404)
          (string-append "Resource not found: "
                         (uri->string (request-uri request)))))

(define (main args)
  (write "Starting web server!")
  (write args)
  (newline)
  (let ((listen (inexact->exact (string->number (car (cdr args))))))
    (display "listening on 8119")
    ;; (write listen)
    (run-server hello-world-handler 'http '(#:port 8119))))
