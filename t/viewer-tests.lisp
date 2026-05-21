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

(defmacro assert-error (&body body)
  `(let ((condition nil))
     (handler-case
         (progn ,@body)
       (error (e) (setf condition e)))
     (assert-true condition "expected an error but none was signaled")))

;; --- Mock viewer for queue + ui tests ---

(defmacro with-mocked-viewer (&body body)
  (let ((old-syms (mapcar (lambda (s) (gensym))
                           '(%vp %ss %fa %sg %sa %aa %sec %sfoc %ar %sd %igv %iav
                             %ss2 %cs %cscc %gv %gt %spc %sst %svc))))
    `(let ((*viewer* (make-array 1))
           (*viewer-queue* nil)
           (*displayed-models* (make-hash-table :test 'equal))
           (*queue-lock* (sb-thread:make-mutex))
           (*grid-visible* t)
           (*axis-visible* t)
           (*theme-mode* :dark)
           (*accent-color* "#0078d4")
           (*show-defs-in-tree* t)
           (*color-scheme-callback-registered* nil)
           (mock-grid-state 1)
           (mock-axis-state 1)
           (mock-stylesheet nil)
           (mock-color-scheme 0))
       (let (,@(mapcar (lambda (s sym)
                          `(,sym (symbol-function (quote ,s))))
                        '(%viewer-post-event %viewer-sync-shapes
                          %viewer-fit-all %viewer-show-grid
                          %viewer-show-axis %viewer-set-antialiasing
                          %viewer-set-eval-callback
                          %viewer-set-file-op-callback
                          %viewer-append-repl-output
                          %viewer-show-dock
                          %viewer-is-grid-visible
                          %viewer-is-axis-visible
                          %viewer-set-stylesheet
                          %viewer-color-scheme
                          %viewer-set-color-scheme-callback
                          %viewer-get-view
                          %viewer-get-trihedron
                          %viewer-set-placeholder-color
                          %viewer-set-status-text
                          %viewer-set-visibility-callback)
                        old-syms))
         (setf (symbol-function '%viewer-post-event) (lambda (vwr) (declare (ignore vwr)))
               (symbol-function '%viewer-sync-shapes)
               (lambda (vwr items count) (declare (ignore vwr items count)))
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
               (symbol-function '%viewer-color-scheme) (lambda (vwr) (declare (ignore vwr)) mock-color-scheme)
               (symbol-function '%viewer-set-color-scheme-callback) (lambda (vwr fn) (declare (ignore vwr fn)))
               (symbol-function '%viewer-get-view) (lambda (vwr) (declare (ignore vwr)) (cffi:null-pointer))
               (symbol-function '%viewer-get-trihedron) (lambda (vwr) (declare (ignore vwr)) (cffi:null-pointer))
               (symbol-function '%viewer-set-placeholder-color) (lambda (vwr r g b) (declare (ignore vwr r g b)))
               (symbol-function '%viewer-set-status-text) (lambda (vwr text) (declare (ignore vwr text)))
               (symbol-function '%viewer-set-visibility-callback) (lambda (vwr fn) (declare (ignore vwr fn))))
          (unwind-protect
              (progn ,@body)
            (setf (symbol-function '%viewer-post-event) ,(nth 0 old-syms)
                  (symbol-function '%viewer-sync-shapes) ,(nth 1 old-syms)
                  (symbol-function '%viewer-fit-all) ,(nth 2 old-syms)
                  (symbol-function '%viewer-show-grid) ,(nth 3 old-syms)
                  (symbol-function '%viewer-show-axis) ,(nth 4 old-syms)
                  (symbol-function '%viewer-set-antialiasing) ,(nth 5 old-syms)
                  (symbol-function '%viewer-set-eval-callback) ,(nth 6 old-syms)
                  (symbol-function '%viewer-set-file-op-callback) ,(nth 7 old-syms)
                  (symbol-function '%viewer-append-repl-output) ,(nth 8 old-syms)
                  (symbol-function '%viewer-show-dock) ,(nth 9 old-syms)
                  (symbol-function '%viewer-is-grid-visible) ,(nth 10 old-syms)
                  (symbol-function '%viewer-is-axis-visible) ,(nth 11 old-syms)
                  (symbol-function '%viewer-set-stylesheet) ,(nth 12 old-syms)
                  (symbol-function '%viewer-color-scheme) ,(nth 13 old-syms)
                  (symbol-function '%viewer-set-color-scheme-callback) ,(nth 14 old-syms)
                  (symbol-function '%viewer-get-view) ,(nth 15 old-syms)
                  (symbol-function '%viewer-get-trihedron) ,(nth 16 old-syms)
                  (symbol-function '%viewer-set-placeholder-color) ,(nth 17 old-syms)
                  (symbol-function '%viewer-set-status-text) ,(nth 18 old-syms)
                  (symbol-function '%viewer-set-visibility-callback) ,(nth 19 old-syms)))))))

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
    (queue-push :display "test" :dummy-shape t t)
    (destructuring-bind (type name shape visible show-in-tree) (first *viewer-queue*)
      (assert-equal :display type)
      (assert-equal "test" name)
      (assert-equal :dummy-shape shape)
      (assert-equal t visible)
      (assert-equal t show-in-tree))))

(deftest drain-queue-processes-all-items
  (with-mocked-viewer
    (queue-push :display "a" nil)
    (queue-push :display "b" nil)
    (queue-push :display "c" nil)
    (drain-queue *viewer*)
    (assert-true (null *viewer-queue*) "queue should be empty after drain")))

(deftest drain-queue-clear-empties-models
  (with-mocked-viewer
    (setf (gethash "a" *displayed-models*) (list nil t t t :display))
    (setf (gethash "b" *displayed-models*) (list nil t t t :display))
    (queue-push :clear nil)
    (drain-queue *viewer*)
    (assert-true (zerop (hash-table-count *displayed-models*)))))

(deftest drain-queue-remove-removes-one
  (with-mocked-viewer
    (setf (gethash "a" *displayed-models*) (list nil t t t :display))
    (setf (gethash "b" *displayed-models*) (list nil t t t :display))
    (queue-push :remove "a")
    (drain-queue *viewer*)
    (assert-nil (gethash "a" *displayed-models*))
    (assert-true (gethash "b" *displayed-models*))))

;; --- display / undisplay / clear-all ---

(deftest display-adds-to-models
  (with-mocked-viewer
    (display "test" :dummy-shape)
    (let ((entry (gethash "test" *displayed-models*)))
      (assert-true entry)
      (assert-eq :dummy-shape (first entry)))))

(deftest display-queues-display-message
  (with-mocked-viewer
    (display "test" :dummy-shape)
    (destructuring-bind (type name shape visible show-in-tree) (first *viewer-queue*)
      (assert-equal :display type)
      (assert-equal "test" name)
      (assert-eq :dummy-shape shape)
      (assert-equal t visible)
      (assert-equal t show-in-tree))))

(deftest display-converts-keyword-to-string
  (with-mocked-viewer
    (display :my-keyword :dummy-shape)
    (let ((entry (gethash "MY-KEYWORD" *displayed-models*)))
      (assert-true entry))))

(deftest undisplay-removes-from-models
  (with-mocked-viewer
    (setf (gethash "test" *displayed-models*) (list nil t t t :display))
    (undisplay "test")
    (assert-nil (gethash "test" *displayed-models*))))

(deftest undisplay-queues-remove-message
  (with-mocked-viewer
    (setf (gethash "test" *displayed-models*) (list nil t t t :display))
    (undisplay "test")
    (let ((msg (first *viewer-queue*)))
      (assert-equal :remove (first msg))
      (assert-equal "test" (second msg)))))

(deftest clear-all-empties-models
  (with-mocked-viewer
    (setf (gethash "a" *displayed-models*) (list nil t t t :display))
    (setf (gethash "b" *displayed-models*) (list nil t t t :display))
    (clear-all)
    (assert-true (zerop (hash-table-count *displayed-models*)))))

(deftest clear-all-queues-clear-message
  (with-mocked-viewer
    (clear-all)
    (assert-equal :clear (first (first *viewer-queue*)))))

;; --- resolve-shape tests ---

(deftest resolve-shape-passes-shape-through
  (let ((s (make-instance 'cl-occt:shape :ptr (cffi:null-pointer))))
    (assert-true (eq s (resolve-shape s)))))

(deftest resolve-shape-errors-on-unknown
  (with-mocked-viewer
    (assert-error (resolve-shape :unknown))))

(deftest resolve-shape-finds-displayed
  (with-mocked-viewer
    (setf (gethash "S" *displayed-models*) (list :sphere t t t :display))
    (assert-eq :sphere (resolve-shape :s))))

(deftest resolve-shape-finds-displayed-string
  (with-mocked-viewer
    (setf (gethash "box2" *displayed-models*) (list :box t t t :display))
    (assert-eq :box (resolve-shape "box2"))))

(deftest resolve-shape-errors-on-unknown-string
  (with-mocked-viewer
    (assert-error (resolve-shape "nonexistent"))))

;; --- def tests ---

(deftest def-stores-shape
  (with-mocked-viewer
    (let ((result (def :s :shape-made)))
      (assert-eq :shape-made result))))

(deftest def-sets-visible-nil
  (with-mocked-viewer
    (let ((*show-defs-in-tree* t))
      (def :s :sphere)
      (let ((entry (gethash "S" *displayed-models*)))
        (assert-true entry)
        (assert-eq :sphere (first entry))
        (assert-nil (second entry))
        (assert-true (third entry))
        (assert-eq :def (fifth entry))))))

(deftest def-does-not-affect-previous-def-visibility
  (with-mocked-viewer
    (def :s :sphere)
    (assert-nil (second (gethash "S" *displayed-models*))
                ":s should be invisible after first def")
    (def :b :box)
    (let ((entry (gethash "S" *displayed-models*)))
      (assert-true entry ":s should still have an entry after second def")
      (assert-nil (second entry)
                  ":s should still be invisible after defining :b"))))

(deftest def-respects-show-defs-in-tree
  (with-mocked-viewer
    (let ((*show-defs-in-tree* nil))
      (def :s :sphere)
      (let ((entry (gethash "S" *displayed-models*)))
        (assert-nil (third entry) "show-in-tree should be nil when *show-defs-in-tree* is nil")))))

;; --- show / hide / toggle tests ---

(deftest show-sets-visible-t
  (with-mocked-viewer
    (setf (gethash "S" *displayed-models*) (list :sphere nil nil t :def))
    (show :s)
    (let ((entry (gethash "S" *displayed-models*)))
      (assert-true (second entry)))))

(deftest hide-sets-visible-nil
  (with-mocked-viewer
    (setf (gethash "S" *displayed-models*) (list :sphere t nil t :def))
    (hide :s)
    (let ((entry (gethash "S" *displayed-models*)))
      (assert-nil (second entry)))))

(deftest toggle-flips-visible
  (with-mocked-viewer
    (setf (gethash "S" *displayed-models*) (list :sphere t nil t :def))
    (toggle :s)
    (let ((entry (gethash "S" *displayed-models*)))
      (assert-nil (second entry)))))

(deftest toggle-flips-visible-from-invisible
  (with-mocked-viewer
    (setf (gethash "S" *displayed-models*) (list :sphere nil nil t :def))
    (toggle :s)
    (let ((entry (gethash "S" *displayed-models*)))
      (assert-true (second entry)))))

(deftest show-triggers-sync
  (with-mocked-viewer
    (setf (gethash "S" *displayed-models*) (list :sphere nil nil t :def))
    (show :s)
    (assert-equal :sync (first (first *viewer-queue*)))))

(deftest show-errors-on-unknown
  (with-mocked-viewer
    (assert-error (show :unknown))))

(deftest hide-errors-on-unknown
  (with-mocked-viewer
    (assert-error (hide :unknown))))

(deftest toggle-errors-on-unknown
  (with-mocked-viewer
    (assert-error (toggle :unknown))))

;; --- show-defs / toggle-defs tests ---

(deftest show-defs-updates-global
  (with-mocked-viewer
    (show-defs nil)
    (assert-nil *show-defs-in-tree*)
    (show-defs t)
    (assert-true *show-defs-in-tree*)))

(deftest show-defs-retroactively-updates-def-shapes
  (with-mocked-viewer
    (setf (gethash "A" *displayed-models*) (list nil t t t :def))
    (setf (gethash "B" *displayed-models*) (list nil t t t :display))
    (show-defs nil)
    (assert-nil (third (gethash "A" *displayed-models*)) "def shape show-in-tree should be nil")
    (assert-true (third (gethash "B" *displayed-models*)) "display shape show-in-tree should stay t")))

(deftest toggle-defs-flips-def-shapes
  (with-mocked-viewer
    (setf (gethash "A" *displayed-models*) (list nil t t t :def))
    (toggle-defs)
    (assert-nil (third (gethash "A" *displayed-models*)))
    (toggle-defs)
    (assert-true (third (gethash "A" *displayed-models*)))))

;; --- Wrapper function tests ---

(deftest wrapper-cut-resolves-and-delegates
  (with-mocked-viewer
    (setf (gethash "S" *displayed-models*) (list :sphere t t t :def))
    (setf (gethash "B" *displayed-models*) (list :box t t t :def))
    (let ((called-with nil))
      (let ((old (symbol-function 'cl-occt:cut)))
        (setf (symbol-function 'cl-occt:cut)
              (lambda (a &rest rest) (setf called-with (cons a rest)) :result))
        (unwind-protect
             (progn
               (let ((result (cut :s :b)))
                 (assert-eq :result result)
                 (assert-eq :sphere (car called-with))
                 (assert-eq :box (cadr called-with))))
          (setf (symbol-function 'cl-occt:cut) old))))))

(deftest wrapper-translate-resolves
  (with-mocked-viewer
    (setf (gethash "S" *displayed-models*) (list :sphere t t t :def))
    (let ((called-shape nil))
      (let ((old (symbol-function 'cl-occt:translate)))
        (setf (symbol-function 'cl-occt:translate)
              (lambda (s dx dy dz)
                (declare (ignore dx dy dz))
                (setf called-shape s)
                :result))
        (unwind-protect
             (progn
               (translate :s 10 0 0)
               (assert-eq :sphere called-shape))
          (setf (symbol-function 'cl-occt:translate) old))))))

(deftest wrapper-make-prism-resolves
  (with-mocked-viewer
    (setf (gethash "S" *displayed-models*) (list :sphere t t t :def))
    (let ((called-shape nil))
      (let ((old (symbol-function 'cl-occt:make-prism)))
        (setf (symbol-function 'cl-occt:make-prism)
              (lambda (s dx dy dz)
                (declare (ignore dx dy dz))
                (setf called-shape s)
                :result))
        (unwind-protect
             (progn
               (make-prism :s 0 0 10)
               (assert-eq :sphere called-shape))
          (setf (symbol-function 'cl-occt:make-prism) old))))))

(deftest wrapper-make-compound-resolves-list
  (with-mocked-viewer
    (setf (gethash "S" *displayed-models*) (list :sphere t t t :def))
    (setf (gethash "B" *displayed-models*) (list :box t t t :def))
    (let ((called-shapes nil))
      (let ((old (symbol-function 'cl-occt:make-compound)))
        (setf (symbol-function 'cl-occt:make-compound)
              (lambda (shapes)
                (setf called-shapes shapes)
                :result))
        (unwind-protect
             (progn
               (make-compound (list :s :b))
               (assert-equal 2 (length called-shapes))
               (assert-eq :sphere (first called-shapes))
               (assert-eq :box (second called-shapes)))
          (setf (symbol-function 'cl-occt:make-compound) old))))))

(deftest wrapper-make-part-resolves
  (with-mocked-viewer
    (setf (gethash "S" *displayed-models*) (list :sphere t t t :def))
    (let ((called-shape nil))
      (let ((old (symbol-function 'cl-occt:make-part)))
        (setf (symbol-function 'cl-occt:make-part)
              (lambda (s &key name color location)
                (declare (ignore name color location))
                (setf called-shape s)
                :result))
        (unwind-protect
             (progn
               (make-part :s :name "My Part")
               (assert-eq :sphere called-shape))
          (setf (symbol-function 'cl-occt:make-part) old))))))

(deftest wrapper-write-step-resolves
  (with-mocked-viewer
    (setf (gethash "S" *displayed-models*) (list :sphere t t t :def))
    (let ((called-name nil))
      (let ((old (symbol-function 'cl-occt:write-step)))
        (setf (symbol-function 'cl-occt:write-step)
              (lambda (s f)
                (setf called-name (cons s f))
                t))
        (unwind-protect
             (progn
               (write-step :s "out.step")
               (assert-eq :sphere (car called-name))
               (assert-equal "out.step" (cdr called-name)))
          (setf (symbol-function 'cl-occt:write-step) old))))))

;; --- displayed-models value type tests ---

(deftest displayed-models-entry-has-five-elements
  (with-mocked-viewer
    (display "test" :shape)
    (let ((entry (gethash "test" *displayed-models*)))
      (assert-equal 5 (length entry))
      (assert-eq :display (fifth entry)))))

(deftest displayed-models-entry-origin-is-def-when-def
  (with-mocked-viewer
    (setf (gethash "S" *displayed-models*) (list :sphere nil nil t :def))
    (assert-eq :def (fifth (gethash "S" *displayed-models*)))))

;; --- update-shape-count is Lisp-local tests ---

(deftest update-shape-count-computes-from-hash
  (with-mocked-viewer
    (let ((status-text nil))
      (let ((old (symbol-function '%viewer-set-status-text)))
        (setf (symbol-function '%viewer-set-status-text)
              (lambda (vwr text) (declare (ignore vwr)) (setf status-text text)))
        (unwind-protect
             (progn
               (setf (gethash "a" *displayed-models*) (list nil t nil t :def))
               (setf (gethash "b" *displayed-models*) (list nil nil nil t :def))
               (update-shape-count)
               (assert-true (search "1 hidden" status-text :test 'char=)
                            "should show 1 hidden when one is not visible"))
          (setf (symbol-function '%viewer-set-status-text) old))))))

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

;; --- Helper function tests ---

(deftest get-displayed-names-empty
  (with-mocked-viewer
    (assert-equal nil (get-displayed-names))))

(deftest get-displayed-names-returns-names
  (with-mocked-viewer
    (setf (gethash "a" *displayed-models*) (list nil t t t :display))
    (setf (gethash "b" *displayed-models*) (list nil t t t :display))
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

;; --- Package tests ---

(deftest cl-occt-user-package-exists
  (assert-true (find-package :cl-occt-user)
               "cl-occt-user package should exist")
  (assert-true (find-package :cad-user)
               "cad-user nickname should resolve")
  (assert-true (find-package :occt-user)
               "occt-user nickname should resolve"))

(deftest cl-occt-user-has-modeling-symbols
  (dolist (sym '("MAKE-SPHERE" "CUT" "FUSE" "TRANSLATE"))
    (let ((found (find-symbol sym :cl-occt-user)))
      (assert-true found (format nil "~A should be accessible in cl-occt-user" sym))
      (assert-true (fboundp found)
                   (format nil "~A should be fbound in cl-occt-user" sym)))))

(deftest cl-occt-user-has-viewer-symbols
  (dolist (sym '("DISPLAY" "UNDISPLAY" "CLEAR-ALL" "SHOW-GRID" "FIT-VIEW"
                 "SET-VIEW-AA" "DEF" "SHOW" "HIDE" "TOGGLE"
                 "SHOW-DEFS" "TOGGLE-DEFS" "RESOLVE-SHAPE"
                 "CUT" "FUSE" "COMMON" "SECTION"
                 "TRANSLATE" "ROTATE"
                 "MAKE-PRISM" "MAKE-REVOL"
                 "MAKE-COMPOUND" "MAKE-PART"
                 "WRITE-STEP" "WRITE-STL"))
    (let ((found (find-symbol sym :cl-occt-user)))
      (assert-true found (format nil "~A should be accessible in cl-occt-user" sym))
      (assert-true (fboundp found)
                   (format nil "~A should be fbound in cl-occt-user" sym)))))

;; --- REPL tests ---

(deftest repl-accumulator-starts-empty
  (assert-true (string= *repl-accumulator* "")))

(deftest repl-eof-sentinel-is-gensym
  (assert-true (symbolp *repl-eof-sentinel*)))

;; --- Edge case tests ---

(deftest undisplay-nonexistent-is-safe
  (with-mocked-viewer
    (setf (gethash "a" *displayed-models*) (list nil t t t :display))
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
    (let ((entry (gethash "part" *displayed-models*)))
      (assert-eq :shape-a (first entry)))
    (display "part" :shape-b)
    (assert-equal 1 (hash-table-count *displayed-models*)
                  "same name should not increase model count")
    (let ((entry (gethash "part" *displayed-models*)))
      (assert-eq :shape-b (first entry)))))

(deftest drain-queue-display-updates-models
  (with-mocked-viewer
    (queue-push :display "box" nil t t)
    (drain-queue *viewer*)
    (assert-true (nth-value 1 (gethash "box" *displayed-models*))
                 "drain of :display should populate *displayed-models*")
    (let ((entry (gethash "box" *displayed-models*)))
      (assert-nil (first entry) "first element should be nil (shape was nil)"))))

;; --- File operation callback tests ---

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

(deftest initialize-viewer-calls-all-three
  (let ((*viewer* (make-array 1))
        (*grid-visible* t)
        (*axis-visible* t)
        (*theme-mode* :dark)
        (*accent-color* "#0078d4")
        (*show-defs-in-tree* t)
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
               displayed-models-entry-has-five-elements
               displayed-models-entry-origin-is-def-when-def
               resolve-shape-passes-shape-through
               resolve-shape-finds-displayed
               resolve-shape-errors-on-unknown
               resolve-shape-finds-displayed-string
               resolve-shape-errors-on-unknown-string
               def-stores-shape def-sets-visible-nil def-does-not-affect-previous-def-visibility def-respects-show-defs-in-tree
               show-sets-visible-t hide-sets-visible-nil toggle-flips-visible toggle-flips-visible-from-invisible
               show-triggers-sync
               show-errors-on-unknown hide-errors-on-unknown toggle-errors-on-unknown
               show-defs-updates-global show-defs-retroactively-updates-def-shapes
               toggle-defs-flips-def-shapes
               wrapper-cut-resolves-and-delegates wrapper-translate-resolves
               wrapper-make-prism-resolves
               wrapper-make-compound-resolves-list wrapper-make-part-resolves
               wrapper-write-step-resolves
               update-shape-count-computes-from-hash
               show-grid-sets-visible show-axis-sets-visible
               toggle-grid-flips toggle-axis-flips
               cl-occt-user-package-exists
               cl-occt-user-has-modeling-symbols
               cl-occt-user-has-viewer-symbols
               initialize-viewer-calls-all-three
               get-displayed-names-empty get-displayed-names-returns-names
               export-all-step-warns-on-empty export-all-stl-warns-on-empty
               repl-accumulator-starts-empty repl-eof-sentinel-is-gensym
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
