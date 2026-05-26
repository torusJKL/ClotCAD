(in-package :clotcad)

(defvar *repl-accumulator* ""
  "Accumulates incomplete REPL input for multiline support.")
(defvar *repl-log* '()
  "List of (input-string . output-string) pairs from REPL and import evaluations.")
(defvar *export-with-output* nil
  "When t, export-repl-history includes results as comments. When nil, code only.")

(defvar *repl-eof-sentinel* (gensym "REPL-EOF")
  "Sentinel value for read-from-string eof-value.")

(defvar *qt-no-modifier* #x00000000)
(defvar *qt-control-modifier* #x04000000)
(defvar *qt-alt-modifier* #x08000000)

;; --- Init file loading ---
(defvar *init-file-path* nil
  "Path to an init file to evaluate at startup. Set by `--init` CLI argument
or defaulted to ~/.config/clotcad/init.lisp. When nil, the default path is
checked.")
(defvar *no-init* nil
  "When t, skip loading any init file at startup. Set by `--no-init` CLI flag.")
(defvar *init-loaded* nil
  "When t, the init file has already been loaded this session.
Prevents double-loading when both bootstrap and start-viewer call their
respective loaders.")

;; --- Lisp file import state ---
(defvar *import-forms* nil
  "List of remaining forms to evaluate during Lisp file import.")
(defvar *import-cancelled* nil
  "When t, the current import will stop after the current form.")
(defvar *import-speed* nil
  "Delay in ms between imported forms. nil = no delay, integer = ms delay.")
(defvar *import-total* 0
  "Total number of forms in the current import.")
(defvar *import-done* 0
  "Number of forms completed in the current import.")

(defun resolve-init-file-path ()
  "Return the path to the init file, or nil if loading is suppressed.
Checks `*no-init*` first. If set, returns nil.
If `*init-file-path*` is set, returns its truename (or warns if missing).
Otherwise checks the default ~/.config/clotcad/init.lisp.
Returns nil when the file does not exist (no warning for default path)."
  (cond
    (*no-init*
     nil)
    (*init-file-path*
     (let ((path (pathname *init-file-path*)))
       (if (probe-file path)
           (truename path)
           (progn
             (format *error-output* ";; Warning: init file not found: ~A~%" *init-file-path*)
             nil))))
    (t
     (let ((path (merge-pathnames ".config/clotcad/init.lisp" (user-homedir-pathname))))
       (when (probe-file path)
         (truename path))))))

(defun load-init-file-ui (vwr)
  "Load an init file and evaluate its forms asynchronously via the
import-tick pipeline. Reads the file, populates `*import-forms*`,
and posts a wake event. Returns t if forms were queued, nil otherwise."
  (when *init-loaded*
    (return-from load-init-file-ui nil))
  (let ((path (resolve-init-file-path)))
    (unless path
      (return-from load-init-file-ui nil))
    (format t ";; Loading init file: ~A~%" path)
    (with-open-file (f path :direction :input)
      (let ((*read-eval* nil)
            (*package* (find-package :clotcad-user))
            (forms '()))
        (loop for form = (read f nil vwr)
              until (eq form vwr)
              do (push form forms))
        (setf *import-forms* (nreverse forms)
              *import-total* (length forms)
              *import-done* 0
              *import-cancelled* nil)
        (setf *init-loaded* t)
        (when *import-forms*
          (%viewer-post-event vwr))))))

(defun load-init-file-headless ()
  "Load an init file and evaluate its forms synchronously.
Each form is eval'd with error handling — errors are printed
to stderr but do not abort remaining forms. Returns t if forms
were evaluated, nil if no init file."
  (when *init-loaded*
    (return-from load-init-file-headless nil))
  (let ((path (resolve-init-file-path)))
    (unless path
      (return-from load-init-file-headless nil))
    (format t ";; Loading init file: ~A~%" path)
    (with-open-file (f path :direction :input)
      (let ((*read-eval* nil)
            (*package* (find-package :clotcad-user))
            (forms '()))
        (loop for form = (read f nil path)
              until (eq form path)
              do (push form forms))
        (setf forms (nreverse forms))
        (dolist (form forms)
          (handler-case
              (eval form)
            (error (e)
              (format *error-output* ";; Init file error: ~A~%" e)))))
      (setf *init-loaded* t)
      t)))

(defun process-import-tick ()
  (when (or *import-cancelled* (null *import-forms*))
    (setf *import-forms* nil *import-cancelled* nil
          *import-total* 0 *import-done* 0)
    (%viewer-set-import-status *viewer* 0 0 0)
    (return-from process-import-tick nil))
  (let ((form (car *import-forms*)))
    (setf *import-forms* (cdr *import-forms*))
    (incf *import-done*)
    (let ((form-text (with-output-to-string (s) (format s "~S" form))))
      (%viewer-append-repl-output *viewer* (format nil "> ~A~%" form-text))
      (let* ((print-output (make-string-output-stream))
             (values (let ((*package* (find-package :clotcad-user))
                           (*standard-output* print-output))
                       (handler-case (multiple-value-list (eval form))
                         (error (e) (list (format nil "Error: ~A" e))))))
             (printed (get-output-stream-string print-output)))
        (let ((output (with-output-to-string (s)
                        (when (plusp (length printed))
                          (write-string printed s))
                        (dolist (v values)
                          (format s "~S~%" v)))))
          (%viewer-append-repl-output *viewer* output)
          (sb-ext:atomic-push (cons form-text output) *repl-log*))))
    (%viewer-set-import-status *viewer* 1 *import-done* *import-total*)
    (if *import-forms*
        (if *import-speed*
            (%viewer-post-event-delayed *viewer* *import-speed*)
            (%viewer-post-event *viewer*))
        (progn
          (setf *import-forms* nil *import-cancelled* nil
                *import-total* 0 *import-done* 0)
          (%viewer-set-import-status *viewer* 0 0 0)))))

(defun cancel-import ()
  "Cancel an active Lisp file import.

  The current form finishes evaluation, then the import stops.

  **Example:**

      (cancel-import)

  **See also:** `replay-speed`"
  (setf *import-cancelled* t))

(defun replay-speed (ms)
  "Set the delay between imported form evaluations.

  MS is in milliseconds. NIL means no delay (evaluate as fast
  as possible). Useful for debugging slow imports.

  - **ms** delay in milliseconds, or `nil` for no delay

  **Example:**

      (replay-speed 500)   ;; wait 500ms between forms
      (replay-speed nil)   ;; no delay

  **See also:** `cancel-import`"
  (setf *import-speed* ms))

(defun log-remote-eval (code-str output-str)
  "Append a code/output pair to the REPL log from a remote connection.

  Used internally by the Slynk and Alive LSP wrappers to record
  remotely-evaluated expressions.

  - **code-str** the evaluated code as a string
  - **output-str** the resulting output as a string

  **Example:**

      (log-remote-eval \"(+ 1 2)\" \"3\")"
  (sb-ext:atomic-push (cons code-str output-str) *repl-log*))

(cffi:defcallback eval-string :void ((code :string) (result :pointer) (maxlen :int))
  (let ((*package* (find-package :clotcad-user)))
    (handler-case
        (let* ((full-code (if (string= *repl-accumulator* "")
                              code
                              (concatenate 'string *repl-accumulator* code)))
               (len (length full-code))
               (pos 0)
               (outputs '()))
          (setf *repl-accumulator* "")
          (loop
            (when (>= pos len) (return))
            (multiple-value-bind (form next-pos)
                (read-from-string full-code nil *repl-eof-sentinel* :start pos)
              (if (eq form *repl-eof-sentinel*)
                  (progn
                    (when (< pos len)
                      (setf *repl-accumulator* (subseq full-code pos)))
                    (return))
                  (let* ((print-output (make-string-output-stream))
                         (values (let ((*standard-output* print-output))
                                   (handler-case (multiple-value-list (eval form))
                                     (error (e) (list (format nil "Error: ~A" e))))))
                         (printed (get-output-stream-string print-output)))
                    (push (with-output-to-string (s)
                            (when (plusp (length printed))
                              (write-string printed s))
                            (dolist (v values)
                              (format s "~S~%" v)))
                          outputs)
                    (setf pos next-pos)))))
          (let ((output (apply #'concatenate 'string (nreverse outputs))))
            (sb-ext:atomic-push (cons full-code output) *repl-log*)
            (cffi:foreign-funcall "snprintf" :pointer result :int maxlen
                                 :string output :int (min (length output) (1- maxlen)) :void)))
      (error (e)
        (setf *repl-accumulator* "")
        (cffi:foreign-funcall "snprintf" :pointer result :int maxlen
                             :string (format nil "Error: ~A~%" e) :int 0 :void)))))

(defun get-displayed-names ()
  (loop for k being the hash-keys of *displayed-models* collect k))

(defun export-all-step (path)
  (when (zerop (hash-table-count *displayed-models*))
    (warn "No shapes to export")
    (return-from export-all-step nil))
  (let ((doc (cl-occt.impl:%xde-new-doc)))
    (unless doc
      (error "Failed to create XDE document"))
    (unwind-protect
         (progn
            (maphash (lambda (name entry)
                       (let* ((shape (first entry))
                              (buf (cffi:foreign-alloc :char :count 256)))
                         (unwind-protect
                              (cl-occt.impl:%xde-add-part
                               doc "" (cl-occt::%ptr shape) name
                               -1 0d0 0d0 0d0 0d0
                               (cffi:null-pointer) buf 256)
                           (cffi:foreign-free buf))))
                     *displayed-models*)
           (let ((result (cl-occt.impl:%xde-write-step doc path)))
             (when (zerop result)
               (error "STEP write failed"))))
      (cl-occt.impl:%xde-free-doc doc))
    t))

(defun export-repl-history (path)
  "Export the REPL session log to a Lisp file.

  Each entry is written as code followed by a newline. If
  `result-export` is T, outputs are included as comments.

  - **path** output file path string

  **Returns:** `t` on success.

  **Example:**

      (export-repl-history \"session.lisp\")
      (result-export t)
      (export-repl-history \"session-with-results.lisp\")

  **See also:** `result-export`"
  (with-open-file (f path :direction :output :if-exists :supersede)
    (dolist (entry (reverse *repl-log*))
      (destructuring-bind (code . output) entry
        (format f "~A~%" code)
        (when *export-with-output*
          (with-input-from-string (s output)
            (loop for line = (read-line s nil nil)
                  while line
                  do (format f "; ~A~%" line)))))))
  t)

(defun result-export (flag)
  "Toggle whether REPL history export includes result values.

  When T, exported history includes output lines as comments.
  When NIL, only code is exported.

  - **flag** boolean, `t` to include results, `nil` for code only

  **Returns:** the new value of `*export-with-output*`.

  **Example:**

      (result-export t)     ;; include results as ; comments
      (result-export nil)   ;; code only (default)

  **See also:** `export-repl-history`"
  (setf *export-with-output* flag))

(defun export-all-stl (path)
  (when (zerop (hash-table-count *displayed-models*))
    (warn "No shapes to export")
    (return-from export-all-stl nil))
  (let ((shapes '()))
    (maphash (lambda (name entry)
               (declare (ignore name))
               (push (first entry) shapes))
             *displayed-models*)
    (let ((compound (cl-occt:make-compound shapes)))
      (cl-occt:write-stl compound path :deflection 0.1))))

(cffi:defcallback handle-file-op :void ((path :string) (op :int))
  (handler-case
      (case op
        (0  ;; import STEP
         (let ((shape (cl-occt:read-step path)))
           (when shape
             (let ((name (format nil "imported-~A" (pathname-name path))))
               (display name shape)
               (%viewer-fit-all *viewer*)))))
        (1  ;; export STEP
         (export-all-step path))
        (2  ;; export STL
         (export-all-stl path))
        (3  ;; import STL
         (let ((shape (cl-occt:read-stl path)))
           (when shape
             (let ((name (format nil "imported-~A" (pathname-name path))))
               (display name shape)
               (%viewer-fit-all *viewer*)))))
        (4  ;; import Lisp file
         (with-open-file (f path :direction :input)
           (let ((*read-eval* nil)
                 (forms '()))
             (loop for form = (read f nil *viewer*)
                   until (eq form *viewer*)
                   do (push form forms))
             (setf *import-forms* (nreverse forms)
                   *import-total* (length forms)
                   *import-done* 0
                   *import-cancelled* nil)
             (when *import-forms*
               (%viewer-post-event *viewer*)))))
        (5  ;; export REPL history
         (export-repl-history path))
        (99 ;; cancel import
         (cancel-import)))
    (error (e)
      (format *error-output* "~&File operation error: ~A~%" e))))

(cffi:defcallback drain-queue-callback :void ()
  (drain-queue *viewer*))

(cffi:defcallback %on-tree-selection :void ((names :pointer) (count :int))
  "Called from C++ when scene tree selection changes."
  (let ((new (make-hash-table :test 'equal)))
    (loop for i below count
          for name = (cffi:mem-aref names :string i)
          do (setf (gethash name new) t))
    (setf *selected* new))
  (sync-selection-to-occt))

(defun set-repl-history-key (modifier)
  "Set the modifier key for REPL history navigation.

  - **modifier** one of `:ctrl` (default), `:none`, `:alt`
    When `:none`, plain Up/Down arrow keys navigate history.

  **Example:**

      (set-repl-history-key :none)   ;; plain arrows for history

  **See also:** `set-repl-submit-key`"
  (%viewer-set-repl-history-modifier *viewer*
    (ecase modifier
      (:ctrl  *qt-control-modifier*)
      (:none  *qt-no-modifier*)
      (:alt   *qt-alt-modifier*))))

(defun set-repl-submit-key (modifier)
  "Set the modifier key for REPL expression submission.

  - **modifier** one of `:none` (default, plain Enter submits),
    `:ctrl` (Ctrl+Enter submits, Enter inserts newline),
    `:alt` (Alt+Enter submits)

  **Example:**

      (set-repl-submit-key :ctrl)   ;; Ctrl+Enter to submit

  **See also:** `set-repl-history-key`"
  (%viewer-set-repl-submit-modifier *viewer*
    (ecase modifier
      (:none  *qt-no-modifier*)
      (:ctrl  *qt-control-modifier*)
      (:alt   *qt-alt-modifier*))))

(defun register-viewer-callbacks (vwr)
  (setf *viewer* vwr)
  (clotcad.impl:%viewer-set-eval-callback vwr (cffi:callback eval-string))
  (clotcad.impl:%viewer-set-file-op-callback vwr (cffi:callback handle-file-op))
  (clotcad.impl:%viewer-set-drain-callback vwr (cffi:callback drain-queue-callback))
  (register-shape-visibility-callback)
  (%viewer-set-tree-selection-callback vwr (cffi:callback %on-tree-selection))
  (register-selection-callback)
  (register-viewcube-callback))
