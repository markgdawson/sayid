;; Sayid nREPL middleware client

(defun sayid-do-buffer-stuff (text l-m orig-buf)
    (pop-to-buffer "*sayid*")
    (read-only-mode 0)
    (erase-buffer)
    (insert text)
    (recenter -1)
    (ansi-color-apply-on-region (point-min) (point-max))
    (sayid-mode)
    (setq meta l-m)
    (pop-to-buffer orig-buf))

(defun sayid-send-and-insert (req)
  (let* ((resp (nrepl-send-sync-request req))
         (x (read (nrepl-dict-get resp "value")))
         (m (nrepl-dict-get resp "meta"))
         (orig-buf (current-buffer)))
    (sayid-do-buffer-stuff x m orig-buf)))

(defun sayid-query-form-at-point ()
  (interactive)
  (sayid-send-and-insert (list "op" "sayid-query-form-at-point"
                               "file" (buffer-file-name)
                               "line" (line-number-at-pos))))

(defun sayid-force-get-inner-trace ()
  (interactive)
  (sayid-send-and-insert (list "op" "sayid-force-get-inner-trace"
                               "source" (buffer-string)
                               "file" (buffer-file-name)
                               "line" (line-number-at-pos))))

(defun sayid-get-workspace ()
  (interactive)
  (sayid-send-and-insert (list "op" "sayid-get-workspace"
                               "source" (buffer-string)
                               "file" (buffer-file-name)
                               "line" (line-number-at-pos))))

(defun sayid-eval-last-sexp ()
  (interactive)
  (nrepl-send-sync-request (list "op" "sayid-clear-log"))
  (nrepl-send-sync-request (list "op" "sayid-trace-all-ns-in-dir"
                                 "dir" (file-name-directory (buffer-file-name))))
  (message (cider-last-sexp))
  (cider-eval-last-sexp)
  (nrepl-send-sync-request (list "op" "sayid-remove-all-traces"))
  (let ((resp (nrepl-send-sync-request (list "op" "sayid-get-workspace")))
        (x (read (nrepl-dict-get resp "value")))
        (m (nrepl-dict-get resp "meta"))
        (orig-buf (current-buffer)))
    (sayid-do-buffer-stuff x m orig-buf)))

(defun sayid-get-line-meta (m n)
  (let ((head (first m))
        (tail (rest m)))
    (cond ((eq nil head) nil)
          ((>= n (first head))
           (second head))
          (t (sayid-get-line-meta tail n)))))

(defun sayid-buffer-nav-from-point ()
  (interactive)
  (let* ((line-meta (sayid-get-line-meta (reverse meta)
                                         (line-number-at-pos)))
         (file (nrepl-dict-get line-meta
                               "file"))
         (line (nrepl-dict-get line-meta
                               "line")))
    (pop-to-buffer (find-buffer-visiting file))
    (goto-line line)))