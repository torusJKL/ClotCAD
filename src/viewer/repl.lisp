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
      (multiple-value-bind (values errorp)
          (handler-case (multiple-value-list (eval form))
            (error (e) (values (list (format nil "Error: ~A" e)) t)))
        (let ((output (with-output-to-string (s)
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
  (setf *import-cancelled* t))

(defun replay-speed (ms)
  (setf *import-speed* ms))

(defun log-remote-eval (code-str output-str)
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
                  (let ((values (handler-case (multiple-value-list (eval form))
                                  (error (e) (list (format nil "Error: ~A" e))))))
                    (push (with-output-to-string (s)
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
  (%viewer-set-repl-history-modifier *viewer*
    (ecase modifier
      (:ctrl  *qt-control-modifier*)
      (:none  *qt-no-modifier*)
      (:alt   *qt-alt-modifier*))))

(defun set-repl-submit-key (modifier)
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
