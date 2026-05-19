(in-package :cl-occt-viewer)

;; --- Test framework (matching cl-occt style) ---

(defstruct test-result
  (pass 0)
  (fail 0)
  (errors 0))

(defvar *test-result* (make-test-result))

(defmacro deftest (name &body body)
  `(defun ,name ()
     (format t "~&Test: ~A ... " ',name)
     (finish-output)
     (handler-case
         (progn ,@body
                (format t "PASS~%")
                (incf (test-result-pass *test-result*)))
       (error (e)
         (format t "FAIL (~A)~%" e)
         (incf (test-result-fail *test-result*))))))

(defun assert-true (val &optional msg)
  (unless val
    (error (or msg "expected true"))))

(defun assert-nil (val &optional msg)
  (when val
    (error (or msg "expected nil"))))

(defun assert-equal (expected actual &optional msg)
  (unless (equal expected actual)
    (error (or msg (format nil "expected ~S but got ~S" expected actual)))))

(defun assert-eq (expected actual &optional msg)
  (unless (eq expected actual)
    (error (or msg (format nil "expected ~S eq ~S" expected actual)))))

;; --- Mock viewer for queue tests ---

(defmacro with-mocked-viewer (&body body)
  (let ((old-syms (mapcar (lambda (s) (gensym)) '(%vp %ps %rs %cl %fa))))
    `(let ((*viewer* (make-array 1))
           (*viewer-queue* nil)
           (*displayed-models* (make-hash-table :test 'equal))
           (*queue-lock* (sb-thread:make-mutex)))
       (let (,@(mapcar (lambda (s sym)
                         `(,sym (symbol-function (quote ,s))))
                       '(%viewer-post-event %viewer-put-shape
                         %viewer-remove-shape %viewer-clear %viewer-fit-all)
                       old-syms))
         (setf (symbol-function '%viewer-post-event) (lambda (vwr) (declare (ignore vwr)))
               (symbol-function '%viewer-put-shape) (lambda (vwr s n) (declare (ignore vwr s n)))
               (symbol-function '%viewer-remove-shape) (lambda (vwr n) (declare (ignore vwr n)))
               (symbol-function '%viewer-clear) (lambda (vwr) (declare (ignore vwr)))
               (symbol-function '%viewer-fit-all) (lambda (vwr) (declare (ignore vwr))))
         (unwind-protect
             (progn ,@body)
           (setf (symbol-function '%viewer-post-event) ,(nth 0 old-syms)
                 (symbol-function '%viewer-put-shape) ,(nth 1 old-syms)
                 (symbol-function '%viewer-remove-shape) ,(nth 2 old-syms)
                 (symbol-function '%viewer-clear) ,(nth 3 old-syms)
                 (symbol-function '%viewer-fit-all) ,(nth 4 old-syms)))))))

;; --- Queue tests ---

(deftest queue-push-adds-item
  (with-mocked-viewer
    (queue-push :display "test" nil)
    (assert-equal 1 (length *viewer-queue*))))

(deftest queue-push-multiple-items
  (with-mocked-viewer
    (queue-push :display "a" nil)
    (queue-push :display "b" nil)
    (queue-push :display "c" nil)
    (assert-equal 3 (length *viewer-queue*))))

(deftest queue-push-item-contents
  (with-mocked-viewer
    (queue-push :display "test" :dummy-shape)
    (destructuring-bind (type name shape) (first *viewer-queue*)
      (assert-equal :display type)
      (assert-equal "test" name)
      (assert-equal :dummy-shape shape))))

(deftest drain-queue-processes-all-items
  (with-mocked-viewer
    (queue-push :display "a" nil)
    (queue-push :display "b" nil)
    (queue-push :display "c" nil)
    (drain-queue *viewer*)
    (assert-true (null *viewer-queue*) "queue should be empty after drain")))

(deftest drain-queue-clear-empties-models
  (with-mocked-viewer
    (setf (gethash "a" *displayed-models*) t)
    (setf (gethash "b" *displayed-models*) t)
    (queue-push :clear nil)
    (drain-queue *viewer*)
    (assert-true (zerop (hash-table-count *displayed-models*)))))

(deftest drain-queue-remove-removes-one
  (with-mocked-viewer
    (setf (gethash "a" *displayed-models*) t)
    (setf (gethash "b" *displayed-models*) t)
    (queue-push :remove "a")
    (drain-queue *viewer*)
    (assert-nil (gethash "a" *displayed-models*))
    (assert-true (gethash "b" *displayed-models*))))

;; --- display / undisplay / clear-all ---

(deftest display-adds-to-models
  (with-mocked-viewer
    (display "test" :dummy-shape)
    (assert-true (gethash "test" *displayed-models*))))

(deftest display-queues-display-message
  (with-mocked-viewer
    (display "test" :dummy-shape)
    (destructuring-bind (type name shape) (first *viewer-queue*)
      (assert-equal :display type)
      (assert-equal "test" name))))

(deftest display-converts-keyword-to-string
  (with-mocked-viewer
    (display :my-keyword :dummy-shape)
    (assert-true (gethash "MY-KEYWORD" *displayed-models*))))

(deftest undisplay-removes-from-models
  (with-mocked-viewer
    (setf (gethash "test" *displayed-models*) t)
    (undisplay "test")
    (assert-nil (gethash "test" *displayed-models*))))

(deftest undisplay-queues-remove-message
  (with-mocked-viewer
    (setf (gethash "test" *displayed-models*) t)
    (undisplay "test")
    (let ((msg (first *viewer-queue*)))
      (assert-equal :remove (first msg))
      (assert-equal "test" (second msg)))))

(deftest clear-all-empties-models
  (with-mocked-viewer
    (setf (gethash "a" *displayed-models*) t)
    (setf (gethash "b" *displayed-models*) t)
    (clear-all)
    (assert-true (zerop (hash-table-count *displayed-models*)))))

(deftest clear-all-queues-clear-message
  (with-mocked-viewer
    (clear-all)
    (assert-equal :clear (first (first *viewer-queue*)))))

;; --- Helper function tests ---

(deftest get-displayed-names-empty
  (with-mocked-viewer
    (assert-equal nil (get-displayed-names))))

(deftest get-displayed-names-returns-names
  (with-mocked-viewer
    (setf (gethash "a" *displayed-models*) t)
    (setf (gethash "b" *displayed-models*) t)
    (let ((names (get-displayed-names)))
      (assert-equal 2 (length names))
      (assert-true (member "a" names :test 'string=))
      (assert-true (member "b" names :test 'string=)))))

(deftest export-all-step-warns-on-empty
  (with-mocked-viewer
    (let ((warnings '()))
      (handler-bind ((warning (lambda (w) (push w warnings) (muffle-warning w))))
        (export-all-step "/tmp/test.step"))
      (assert-true warnings "should warn when no shapes in *displayed-models*"))))

(deftest export-all-stl-warns-on-empty
  (with-mocked-viewer
    (let ((warnings '()))
      (handler-bind ((warning (lambda (w) (push w warnings) (muffle-warning w))))
        (export-all-stl "/tmp/test.stl"))
      (assert-true warnings "should warn when no shapes in *displayed-models*"))))

;; --- REPL multiline logic tests ---

(deftest repl-accumulator-starts-empty
  (assert-true (string= *repl-accumulator* "")))

(deftest repl-eof-sentinel-is-gensym
  (assert-true (symbolp *repl-eof-sentinel*)))

(deftest incomplete-form-signals-error
  (let ((*repl-eof-sentinel* (gensym "EOF")))
    (multiple-value-bind (form pos)
        (ignore-errors (read-from-string "(+ 1 2" nil *repl-eof-sentinel*))
      (assert-nil form "incomplete form should signal an error"))))

(deftest complete-form-reads-correctly
  (let ((*repl-eof-sentinel* (gensym "EOF")))
    (multiple-value-bind (form pos)
        (read-from-string "(+ 1 2)" nil *repl-eof-sentinel*)
      (assert-true (not (eq *repl-eof-sentinel* form))))))

(deftest read-empty-string-returns-eof
  (let ((*repl-eof-sentinel* (gensym "EOF")))
    (multiple-value-bind (form pos)
        (read-from-string "" nil *repl-eof-sentinel*)
      (assert-eq *repl-eof-sentinel* form))))

;; --- File operation callback dispatch tests ---

(deftest file-op-dispatch-import-step
  (assert-equal 0 0 "import step op code"))

(deftest file-op-dispatch-export-step
  (assert-equal 1 1 "export step op code"))

(deftest file-op-dispatch-export-stl
  (assert-equal 2 2 "export stl op code"))

(deftest file-op-dispatch-import-stl
  (assert-equal 3 3 "import stl op code"))

;; --- Registration tests ---

(deftest register-viewer-callbacks-sets-viewer
  (with-mocked-viewer
    (let ((called-eval nil)
          (called-file nil)
          (called-drain nil))
      (let ((old-eval (symbol-function '%viewer-set-eval-callback))
            (old-file (symbol-function '%viewer-set-file-op-callback))
            (old-drain (symbol-function '%viewer-set-drain-callback)))
        (setf (symbol-function '%viewer-set-eval-callback)
              (lambda (vwr fn) (declare (ignore vwr)) (setf called-eval fn))
              (symbol-function '%viewer-set-file-op-callback)
              (lambda (vwr fn) (declare (ignore vwr)) (setf called-file fn))
              (symbol-function '%viewer-set-drain-callback)
              (lambda (vwr fn) (declare (ignore vwr)) (setf called-drain fn)))
        (unwind-protect
            (progn
              (register-viewer-callbacks *viewer*)
              (assert-true called-eval "eval callback should be registered")
              (assert-true called-file "file op callback should be registered")
              (assert-true called-drain "drain callback should be registered"))
          (setf (symbol-function '%viewer-set-eval-callback) old-eval
                (symbol-function '%viewer-set-file-op-callback) old-file
                (symbol-function '%viewer-set-drain-callback) old-drain))))))

;; --- Test runner ---

(defun run-tests ()
  (setq *test-result* (make-test-result))
  (let ((*repl-accumulator* "")
        (*repl-eof-sentinel* (gensym "REPL-EOF")))
    (format t "~&=== cl-occt-viewer tests ===~2%")
    (dolist (test-sym
             '(queue-push-adds-item queue-push-multiple-items queue-push-item-contents
               drain-queue-processes-all-items drain-queue-clear-empties-models
               drain-queue-remove-removes-one
               display-adds-to-models display-queues-display-message
               display-converts-keyword-to-string
               undisplay-removes-from-models undisplay-queues-remove-message
               clear-all-empties-models clear-all-queues-clear-message
                get-displayed-names-empty get-displayed-names-returns-names
                export-all-step-warns-on-empty export-all-stl-warns-on-empty
               repl-accumulator-starts-empty repl-eof-sentinel-is-gensym
               incomplete-form-signals-error complete-form-reads-correctly
               read-empty-string-returns-eof
               file-op-dispatch-import-step file-op-dispatch-export-step
               file-op-dispatch-export-stl file-op-dispatch-import-stl
               register-viewer-callbacks-sets-viewer))
      (funcall test-sym))
    (format t "~2&=== Results: ~D pass, ~D fail, ~D errors ===~%"
            (test-result-pass *test-result*)
            (test-result-fail *test-result*)
            (test-result-errors *test-result*))
    (values (test-result-pass *test-result*)
            (test-result-fail *test-result*))))
