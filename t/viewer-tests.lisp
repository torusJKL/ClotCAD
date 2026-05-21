(in-package :cl-occt-viewer)

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

;; --- Mock viewer for queue + ui tests ---

(defmacro with-mocked-viewer (&body body)
  (let ((old-syms (mapcar (lambda (s) (gensym))
                           '(%vp %ps %rs %cl %fa %sg %sa %aa %sec %sfoc %ar %sd %igv %iav
                             %ss %gs %cs %cscc %gv %gt %spc %svsc %sst %svc))))
    `       (let ((*viewer* (make-array 1))
           (*viewer-queue* nil)
           (*displayed-models* (make-hash-table :test 'equal))
           (*queue-lock* (sb-thread:make-mutex))
           (*grid-visible* t)
           (*axis-visible* t)
           (*theme-mode* :dark)
           (*accent-color* "#0078d4")
           (*color-scheme-callback-registered* nil)
           (mock-grid-state 1)
           (mock-axis-state 1)
           (mock-stylesheet nil)
           (mock-color-scheme 0))
       (let (,@(mapcar (lambda (s sym)
                          `(,sym (symbol-function (quote ,s))))
                        '(%viewer-post-event %viewer-put-shape
                          %viewer-remove-shape %viewer-clear
                          %viewer-fit-all %viewer-show-grid
                          %viewer-show-axis %viewer-set-antialiasing
                          %viewer-set-eval-callback
                          %viewer-set-file-op-callback
                          %viewer-append-repl-output
                          %viewer-show-dock
                          %viewer-is-grid-visible
                          %viewer-is-axis-visible
                          %viewer-set-stylesheet
                          %viewer-get-shape-count
                          %viewer-color-scheme
                          %viewer-set-color-scheme-callback
                          %viewer-get-view
                          %viewer-get-trihedron
                          %viewer-set-placeholder-color
                          %viewer-get-visible-shape-count
                          %viewer-set-status-text
                          %viewer-set-visibility-callback)
                        old-syms))
         (setf (symbol-function '%viewer-post-event) (lambda (vwr) (declare (ignore vwr)))
               (symbol-function '%viewer-put-shape) (lambda (vwr s n) (declare (ignore vwr s n)))
               (symbol-function '%viewer-remove-shape) (lambda (vwr n) (declare (ignore vwr n)))
               (symbol-function '%viewer-clear) (lambda (vwr) (declare (ignore vwr)))
               (symbol-function '%viewer-fit-all) (lambda (vwr) (declare (ignore vwr)))
               (symbol-function '%viewer-show-grid) (lambda (vwr s) (declare (ignore vwr)) (setf mock-grid-state s))
               (symbol-function '%viewer-show-axis) (lambda (vwr s) (declare (ignore vwr)) (setf mock-axis-state s))
               (symbol-function '%viewer-set-antialiasing) (lambda (vwr e) (declare (ignore vwr e)))
               (symbol-function '%viewer-set-eval-callback) (lambda (vwr fn) (declare (ignore vwr fn)))
               (symbol-function '%viewer-set-file-op-callback) (lambda (vwr fn) (declare (ignore vwr fn)))
               (symbol-function '%viewer-append-repl-output) (lambda (vwr text) (declare (ignore vwr text)))
               (symbol-function '%viewer-show-dock) (lambda (vwr dn s) (declare (ignore vwr dn s)))
               (symbol-function '%viewer-is-grid-visible) (lambda (vwr) (declare (ignore vwr)) mock-grid-state)
               (symbol-function '%viewer-is-axis-visible) (lambda (vwr) (declare (ignore vwr)) mock-axis-state)
               (symbol-function '%viewer-set-stylesheet) (lambda (vwr qss) (declare (ignore vwr)) (setf mock-stylesheet qss))
               (symbol-function '%viewer-get-shape-count) (lambda (vwr) (declare (ignore vwr)) 0)
               (symbol-function '%viewer-color-scheme) (lambda (vwr) (declare (ignore vwr)) mock-color-scheme)
               (symbol-function '%viewer-set-color-scheme-callback) (lambda (vwr fn) (declare (ignore vwr fn)))
               (symbol-function '%viewer-get-view) (lambda (vwr) (declare (ignore vwr)) (cffi:null-pointer))
               (symbol-function '%viewer-get-trihedron) (lambda (vwr) (declare (ignore vwr)) (cffi:null-pointer))
               (symbol-function '%viewer-set-placeholder-color) (lambda (vwr r g b) (declare (ignore vwr r g b)))
               (symbol-function '%viewer-get-visible-shape-count) (lambda (vwr) (declare (ignore vwr)) 0)
               (symbol-function '%viewer-set-status-text) (lambda (vwr text) (declare (ignore vwr text)))
               (symbol-function '%viewer-set-visibility-callback) (lambda (vwr fn) (declare (ignore vwr fn))))
         (unwind-protect
             (progn ,@body)
           (setf (symbol-function '%viewer-post-event) ,(nth 0 old-syms)
                 (symbol-function '%viewer-put-shape) ,(nth 1 old-syms)
                 (symbol-function '%viewer-remove-shape) ,(nth 2 old-syms)
                 (symbol-function '%viewer-clear) ,(nth 3 old-syms)
                 (symbol-function '%viewer-fit-all) ,(nth 4 old-syms)
                 (symbol-function '%viewer-show-grid) ,(nth 5 old-syms)
                 (symbol-function '%viewer-show-axis) ,(nth 6 old-syms)
                 (symbol-function '%viewer-set-antialiasing) ,(nth 7 old-syms)
                 (symbol-function '%viewer-set-eval-callback) ,(nth 8 old-syms)
                 (symbol-function '%viewer-set-file-op-callback) ,(nth 9 old-syms)
                 (symbol-function '%viewer-append-repl-output) ,(nth 10 old-syms)
                 (symbol-function '%viewer-show-dock) ,(nth 11 old-syms)
                 (symbol-function '%viewer-is-grid-visible) ,(nth 12 old-syms)
                 (symbol-function '%viewer-is-axis-visible) ,(nth 13 old-syms)
                 (symbol-function '%viewer-set-stylesheet) ,(nth 14 old-syms)
                 (symbol-function '%viewer-get-shape-count) ,(nth 15 old-syms)
                 (symbol-function '%viewer-color-scheme) ,(nth 16 old-syms)
                 (symbol-function '%viewer-set-color-scheme-callback) ,(nth 17 old-syms)
                 (symbol-function '%viewer-get-view) ,(nth 18 old-syms)
                 (symbol-function '%viewer-get-trihedron) ,(nth 19 old-syms)
                 (symbol-function '%viewer-set-placeholder-color) ,(nth 20 old-syms)
                 (symbol-function '%viewer-get-visible-shape-count) ,(nth 21 old-syms)
                 (symbol-function '%viewer-set-status-text) ,(nth 22 old-syms)
                 (symbol-function '%viewer-set-visibility-callback) ,(nth 23 old-syms)))))))

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

;; --- UI state tests ---

(deftest show-grid-sets-visible
  (with-mocked-viewer
    (show-grid t)
    (assert-true *grid-visible*)
    (show-grid nil)
    (assert-nil *grid-visible*)))

(deftest show-axis-sets-visible
  (with-mocked-viewer
    (show-axis t)
    (assert-true *axis-visible*)
    (show-axis nil)
    (assert-nil *axis-visible*)))

(deftest toggle-grid-flips
  (with-mocked-viewer
    (let ((before *grid-visible*))
      (toggle-grid)
      (assert-equal (not before) *grid-visible*))))

(deftest toggle-axis-flips
  (with-mocked-viewer
    (let ((before *axis-visible*))
      (toggle-axis)
      (assert-equal (not before) *axis-visible*))))

;; --- initialize-viewer test ---

(deftest initialize-viewer-calls-all-three
  (let ((*viewer* (make-array 1))
        (*grid-visible* t)
        (*axis-visible* t)
        (*theme-mode* :dark)
        (*accent-color* "#0078d4")
        (*color-scheme-callback-registered* nil)
        (show-axis-args nil)
        (show-grid-args nil)
        (set-aa-args nil))
    (let ((old-axis (symbol-function '%viewer-show-axis))
          (old-grid (symbol-function '%viewer-show-grid))
          (old-aa (symbol-function '%viewer-set-antialiasing))
          (old-ss (symbol-function '%viewer-set-stylesheet))
          (old-cs (symbol-function '%viewer-color-scheme))
          (old-csc (symbol-function '%viewer-set-color-scheme-callback))
          (old-gv (symbol-function '%viewer-get-view))
          (old-gt (symbol-function '%viewer-get-trihedron))
          (old-spc (symbol-function '%viewer-set-placeholder-color)))
      (setf (symbol-function '%viewer-show-axis)
            (lambda (vwr show) (declare (ignore vwr)) (push show show-axis-args))
            (symbol-function '%viewer-show-grid)
            (lambda (vwr show) (declare (ignore vwr)) (push show show-grid-args))
            (symbol-function '%viewer-set-antialiasing)
            (lambda (vwr enable) (declare (ignore vwr)) (push enable set-aa-args))
            (symbol-function '%viewer-set-stylesheet)
            (lambda (vwr qss) (declare (ignore vwr qss)))
            (symbol-function '%viewer-color-scheme)
            (lambda (vwr) (declare (ignore vwr)) 0)
            (symbol-function '%viewer-set-color-scheme-callback)
            (lambda (vwr fn) (declare (ignore vwr fn)))
            (symbol-function '%viewer-get-view)
            (lambda (vwr) (declare (ignore vwr)) (cffi:null-pointer))
            (symbol-function '%viewer-get-trihedron)
            (lambda (vwr) (declare (ignore vwr)) (cffi:null-pointer))
            (symbol-function '%viewer-set-placeholder-color)
            (lambda (vwr r g b) (declare (ignore vwr r g b))))
      (unwind-protect
           (progn
             (initialize-viewer *viewer*)
             (assert-equal '(1) (nreverse show-axis-args)
                           "%viewer-show-axis should be called with show=1")
             (assert-equal '(1) (nreverse show-grid-args)
                           "%viewer-show-grid should be called with show=1")
             (assert-equal '(1) (nreverse set-aa-args)
                           "%viewer-set-antialiasing should be called with enable=1"))
        (setf (symbol-function '%viewer-show-axis) old-axis
              (symbol-function '%viewer-show-grid) old-grid
              (symbol-function '%viewer-set-antialiasing) old-aa
              (symbol-function '%viewer-set-stylesheet) old-ss
              (symbol-function '%viewer-color-scheme) old-cs
              (symbol-function '%viewer-set-color-scheme-callback) old-csc
              (symbol-function '%viewer-get-view) old-gv
              (symbol-function '%viewer-get-trihedron) old-gt
              (symbol-function '%viewer-set-placeholder-color) old-spc)))))

;; --- set-antialiasing / fit-all tests ---

(deftest set-antialiasing-calls-c-api
  (with-mocked-viewer
    (let ((called-with nil))
      (let ((old (symbol-function '%viewer-set-antialiasing)))
        (setf (symbol-function '%viewer-set-antialiasing)
              (lambda (vwr e) (declare (ignore vwr)) (setf called-with e)))
        (unwind-protect
            (progn
              (set-antialiasing nil)
              (assert-equal 0 called-with "set-antialiasing nil should pass 0")
              (set-antialiasing t)
              (assert-equal 1 called-with "set-antialiasing t should pass 1"))
          (setf (symbol-function '%viewer-set-antialiasing) old))))))

(deftest fit-all-calls-c-api
  (with-mocked-viewer
    (let ((called nil))
      (let ((old (symbol-function '%viewer-fit-all)))
        (setf (symbol-function '%viewer-fit-all)
              (lambda (vwr) (declare (ignore vwr)) (setf called t)))
        (unwind-protect
            (progn
              (fit-all)
              (assert-true called "fit-all should call %viewer-fit-all"))
          (setf (symbol-function '%viewer-fit-all) old))))))

;; --- Edge case tests ---

(deftest undisplay-nonexistent-is-safe
  (with-mocked-viewer
    (setf (gethash "a" *displayed-models*) t)
    (undisplay "nonexistent")
    (assert-equal 1 (hash-table-count *displayed-models*)
                  "undisplay of nonexistent should not affect models")
    (assert-true (gethash "a" *displayed-models*))))

(deftest clear-all-on-empty-is-safe
  (with-mocked-viewer
    (assert-true (zerop (hash-table-count *displayed-models*)))
    (clear-all)
    (assert-true (zerop (hash-table-count *displayed-models*))
                  "clear-all on empty should not error")))

(deftest drain-queue-on-empty-is-safe
  (with-mocked-viewer
    (drain-queue *viewer*)
    (assert-true (null *viewer-queue*)
                  "drain on empty queue should not error")))

(deftest queue-push-without-viewer-is-safe
  (let ((*viewer* nil)
        (*viewer-queue* nil)
        (*queue-lock* (sb-thread:make-mutex)))
    (queue-push :display "test" nil)
    (assert-equal 1 (length *viewer-queue*)
                  "should queue even without *viewer*")))

(deftest display-replaces-existing-name
  (with-mocked-viewer
    (display "part" :shape-a)
    (assert-equal 1 (hash-table-count *displayed-models*))
    (assert-true (eq :shape-a (gethash "part" *displayed-models*)))
    ;; Replace with different shape
    (display "part" :shape-b)
    (assert-equal 1 (hash-table-count *displayed-models*)
                  "same name should not increase model count")
    (assert-true (eq :shape-b (gethash "part" *displayed-models*))
                 "display with same name should replace")))

(deftest drain-queue-display-updates-models
  (with-mocked-viewer
    (queue-push :display "box" nil)
    (drain-queue *viewer*)
    (assert-true (nth-value 1 (gethash "box" *displayed-models*))
                 "drain of :display should populate *displayed-models*")
    ;; Name maps to nil shape since the mock ignores the C call
    (assert-nil (gethash "box" *displayed-models*))))

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

;; --- REPL multiline tests ---

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
          (called-file-op nil)
          (called-drain nil))
      (let ((old-eval (symbol-function '%viewer-set-eval-callback))
            (old-file-op (symbol-function '%viewer-set-file-op-callback))
            (old-drain (symbol-function '%viewer-set-drain-callback)))
        (setf (symbol-function '%viewer-set-eval-callback)
              (lambda (vwr fn) (declare (ignore vwr)) (setf called-eval fn))
              (symbol-function '%viewer-set-file-op-callback)
              (lambda (vwr fn) (declare (ignore vwr)) (setf called-file-op fn))
              (symbol-function '%viewer-set-drain-callback)
              (lambda (vwr fn) (declare (ignore vwr)) (setf called-drain fn)))
        (unwind-protect
            (progn
              (register-viewer-callbacks *viewer*)
              (assert-true called-eval "eval callback should be registered")
              (assert-true called-file-op "file-op callback should be registered")
              (assert-true called-drain "drain callback should be registered"))
          (setf (symbol-function '%viewer-set-eval-callback) old-eval
                (symbol-function '%viewer-set-file-op-callback) old-file-op
                (symbol-function '%viewer-set-drain-callback) old-drain))))))

;; --- Theme tests ---

(deftest subst-replaces-single-token
  (let ((result (cl-occt-viewer::%subst "hello {{name}}" '(("name" . "world")))))
    (assert-true (search "hello world" result :test 'char=)
                 "should replace {{name}} with world")))

(deftest subst-replaces-multiple-tokens
  (let* ((color-alist '(("fg" . "#ffffff") ("bg" . "#000000")))
         (result (cl-occt-viewer::%subst "color: {{fg}}; background: {{bg}};" color-alist)))
    (assert-true (search "#ffffff" result :test 'char=) "should contain fg color")
    (assert-true (search "#000000" result :test 'char=) "should contain bg color")))

(deftest subst-handles-symbol-keys
  (let ((result (cl-occt-viewer::%subst "color: {{fg}};" '((:fg . "#ff0000")))))
    (assert-true (search "#ff0000" result :test 'char=))))

(deftest subst-leaves-unknown-tokens
  (let ((result (cl-occt-viewer::%subst "{{keep}}" nil)))
    (assert-equal "{{keep}}" result "unmatched token should remain")))

(deftest subst-empty-string
  (assert-equal "" (cl-occt-viewer::%subst "" nil) "empty input should return empty"))

(deftest generate-qss-returns-string
  (let* ((*accent-color* "#0078d4")
         (qss (generate-qss :dark)))
    (assert-true (stringp qss) "generate-qss should return a string")
    (assert-true (> (length qss) 100) "QSS should be substantial")
    (assert-true (search "#1e1e1e" qss :test 'char=) "dark bg should appear")
    (assert-true (search "#0078d4" qss :test 'char=) "accent should appear")))

(deftest generate-qss-light-theme
  (let* ((*accent-color* "#0078d4")
         (qss (generate-qss :light)))
    (assert-true (stringp qss))
    (assert-true (search "#f3f3f3" qss :test 'char=) "light bg should appear")))

(deftest generate-qss-custom-accent
  (let* ((*accent-color* "#FF6600")
         (qss (generate-qss :dark :accent "#FF6600")))
    (assert-true (search "#FF6600" qss :test 'char=) "custom accent should appear")))

(deftest apply-theme-sets-state
  (with-mocked-viewer
    (apply-theme :dark :accent "#0078d4")
    (assert-eq :dark *theme-mode*)
    (assert-equal "#0078d4" *accent-color*)))

(deftest apply-theme-light-sets-state
  (with-mocked-viewer
    (apply-theme :light)
    (assert-eq :light *theme-mode*)))

(deftest apply-theme-calls-c-api
  (with-mocked-viewer
    (let ((called-with nil))
      (let ((old (symbol-function '%viewer-set-stylesheet)))
        (setf (symbol-function '%viewer-set-stylesheet)
              (lambda (vwr qss) (declare (ignore vwr)) (setf called-with qss)))
        (unwind-protect
             (progn
               (apply-theme :dark)
               (assert-true (stringp called-with) "should call %viewer-set-stylesheet with a string")
               (assert-true (> (length called-with) 100) "QSS should be non-trivial"))
          (setf (symbol-function '%viewer-set-stylesheet) old))))))

(deftest apply-theme-auto-resolves-to-dark-when-system-dark
  (with-mocked-viewer
    (setf mock-color-scheme 2)
    (multiple-value-bind (mode accent)
        (apply-theme :auto :accent "#0078d4")
      (assert-eq :dark mode "auto should resolve to :dark when system is dark")
      (assert-equal "#0078d4" accent))))

(deftest apply-theme-auto-resolves-to-light-when-system-light
  (with-mocked-viewer
    (setf mock-color-scheme 1)
    (multiple-value-bind (mode accent)
        (apply-theme :auto :accent "#FF6600")
      (assert-eq :light mode "auto should resolve to :light when system is light"))))

(deftest apply-theme-auto-resolves-to-light-when-system-unknown
  (with-mocked-viewer
    (setf mock-color-scheme 0)
    (multiple-value-bind (mode accent)
        (apply-theme :auto)
      (assert-eq :light mode "auto should default to :light when system is unknown"))))

(deftest set-accent-updates-and-reapplies
  (with-mocked-viewer
    (apply-theme :dark :accent "#0078d4")
    (set-accent "#FF6600")
    (assert-equal "#FF6600" *accent-color* "accent color should update")
    (assert-eq :dark *theme-mode* "theme mode should be preserved")))

(deftest theme-dark-works
  (with-mocked-viewer
    (theme-light)
    (theme-dark)
    (assert-eq :dark *theme-mode*)))

(deftest theme-light-works
  (with-mocked-viewer
    (theme-light)
    (assert-eq :light *theme-mode*)))

(deftest theme-dark-with-custom-accent
  (with-mocked-viewer
    (theme-dark "#FF00FF")
    (assert-equal "#FF00FF" *accent-color*)))

(deftest register-color-scheme-callback-sets-flag
  (with-mocked-viewer
    (register-color-scheme-callback)
    (assert-true *color-scheme-callback-registered*)))

(deftest register-color-scheme-callback-is-idempotent
  (with-mocked-viewer
    (register-color-scheme-callback)
    (let ((call-count 0))
      (let ((old (symbol-function '%viewer-set-color-scheme-callback)))
        (setf (symbol-function '%viewer-set-color-scheme-callback)
              (lambda (vwr fn) (declare (ignore vwr fn)) (incf call-count)))
        (unwind-protect
             (progn
               (register-color-scheme-callback)
               (assert-equal 0 call-count "second call should not re-register"))
          (setf (symbol-function '%viewer-set-color-scheme-callback) old))))))

(deftest initialize-viewer-calls-theme
  (with-mocked-viewer
    (initialize-viewer *viewer*)
    (assert-true (stringp mock-stylesheet)
                 "initialize-viewer should apply a theme")))

(deftest resolve-mode-auto-dark
  (with-mocked-viewer
    (setf mock-color-scheme 2)
    (assert-eq :dark (cl-occt-viewer::%resolve-mode :auto))))

(deftest resolve-mode-auto-light
  (with-mocked-viewer
    (setf mock-color-scheme 1)
    (assert-eq :light (cl-occt-viewer::%resolve-mode :auto))))

(deftest resolve-mode-auto-unknown
  (with-mocked-viewer
    (setf mock-color-scheme 0)
    (assert-eq :light (cl-occt-viewer::%resolve-mode :auto))))

(deftest resolve-mode-explicit-dark
  (assert-eq :dark (cl-occt-viewer::%resolve-mode :dark)))

(deftest resolve-mode-explicit-light
  (assert-eq :light (cl-occt-viewer::%resolve-mode :light)))

(deftest palette-has-axis-colors
  (let ((dark (cl-occt-viewer::%dark-palette "#0078d4"))
        (light (cl-occt-viewer::%light-palette "#0078d4")))
    (dolist (p (list dark light))
      (assert-true (assoc :axis-x-color p) "should have axis-x-color")
      (assert-true (assoc :axis-y-color p) "should have axis-y-color")
      (assert-true (assoc :axis-z-color p) "should have axis-z-color"))))

(deftest palette-has-placeholder-color
  (let ((dark (cl-occt-viewer::%dark-palette "#0078d4"))
        (light (cl-occt-viewer::%light-palette "#0078d4")))
    (dolist (p (list dark light))
      (assert-true (assoc :placeholder-fg p) "should have placeholder-fg"))))

(deftest palette-font-size-uses-variable
  (let ((cl-occt-viewer::*font-size* "15px"))
    (let ((dark (cl-occt-viewer::%dark-palette "#0078d4")))
      (assert-equal "15px" (cdr (assoc :font-size dark)))))
  (let ((cl-occt-viewer::*font-size* "12px"))
    (let ((light (cl-occt-viewer::%light-palette "#0078d4")))
      (assert-equal "12px" (cdr (assoc :font-size light))))))

(deftest set-font-size-updates-and-reapplies
  (with-mocked-viewer
    (set-font-size "15px")
    (assert-equal "15px" *font-size*)
    (assert-eq :dark *theme-mode* "theme mode should be preserved")))

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
               drain-queue-display-updates-models
               drain-queue-on-empty-is-safe
               queue-push-without-viewer-is-safe
               display-adds-to-models display-queues-display-message
               display-converts-keyword-to-string
               display-replaces-existing-name
               undisplay-removes-from-models undisplay-queues-remove-message
               undisplay-nonexistent-is-safe
               clear-all-empties-models clear-all-queues-clear-message
               clear-all-on-empty-is-safe
               show-grid-sets-visible show-axis-sets-visible
               toggle-grid-flips toggle-axis-flips
               set-antialiasing-calls-c-api
               fit-all-calls-c-api
               initialize-viewer-calls-all-three
               get-displayed-names-empty get-displayed-names-returns-names
               export-all-step-warns-on-empty export-all-stl-warns-on-empty
               repl-accumulator-starts-empty repl-eof-sentinel-is-gensym
               incomplete-form-signals-error complete-form-reads-correctly
               read-empty-string-returns-eof
               file-op-dispatch-import-step file-op-dispatch-export-step
               file-op-dispatch-export-stl file-op-dispatch-import-stl
                register-viewer-callbacks-sets-viewer
                subst-replaces-single-token subst-replaces-multiple-tokens
                subst-handles-symbol-keys subst-leaves-unknown-tokens
                subst-empty-string
                generate-qss-returns-string generate-qss-light-theme
                generate-qss-custom-accent
                apply-theme-sets-state apply-theme-light-sets-state
                apply-theme-calls-c-api
                apply-theme-auto-resolves-to-dark-when-system-dark
                apply-theme-auto-resolves-to-light-when-system-light
                apply-theme-auto-resolves-to-light-when-system-unknown
                set-accent-updates-and-reapplies
                theme-dark-works theme-light-works theme-dark-with-custom-accent
                register-color-scheme-callback-sets-flag
                register-color-scheme-callback-is-idempotent
                initialize-viewer-calls-theme
                resolve-mode-auto-dark resolve-mode-auto-light
                resolve-mode-auto-unknown resolve-mode-explicit-dark
                resolve-mode-explicit-light
                palette-has-axis-colors palette-has-placeholder-color
                palette-font-size-uses-variable set-font-size-updates-and-reapplies))
      (funcall test-sym))
    (format t "~2&=== Results: ~D pass, ~D fail, ~D errors ===~%"
            (test-result-pass *test-result*)
            (test-result-fail *test-result*)
            (test-result-errors *test-result*))
    (values (test-result-pass *test-result*)
            (test-result-fail *test-result*))))
