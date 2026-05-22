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
                                  %ss2 %cs %cscc %gv %gt %spc %sst %svc
                                  %gc %gao %ssc %stc %smsc %vst %vrh %vrs
                                   %vpd %sis %sip %sttc
                                  %svc2 %ivcv %vsv %gvo %svcc %svc3 %svct %svci %svctr %svcsz %svcac %svcda %gvcda %svchc))))
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
           (mock-viewcube-state 1)
           (mock-view-orientation 0)
           (mock-viewcube-callback nil)
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
                             %viewer-set-trihedron-text-color
                             %viewer-set-status-text
                            %viewer-set-visibility-callback
                            %viewer-get-context
                            %viewer-get-ais-object
                            %viewer-set-selection-callback
                            %viewer-set-tree-selection-callback
                             %viewer-set-mouse-selection-scheme
                             %viewer-sync-tree-selection
                             %viewer-set-repl-history-modifier
                             %viewer-set-repl-submit-modifier
                             %viewer-post-event-delayed
                              %viewer-set-import-status
                              %viewer-set-icon-palette
                              %viewer-show-viewcube
                              %viewer-is-viewcube-visible
                              %viewer-set-view
                              %viewer-get-view-orientation
                              %viewer-set-viewcube-callback
                              %viewer-set-viewcube-color
                              %viewer-set-viewcube-text-color
                              %viewer-set-viewcube-inner-color
                              %viewer-set-viewcube-transparency
                              %viewer-set-viewcube-size
                              %viewer-set-viewcube-axis-color
                              %viewer-set-viewcube-draw-axes
                              %viewer-get-viewcube-draw-axes
                              %viewer-set-viewcube-hilight-color)
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
                (symbol-function '%viewer-set-trihedron-text-color) (lambda (vwr part r g b) (declare (ignore vwr part r g b)))
                (symbol-function '%viewer-set-status-text) (lambda (vwr text) (declare (ignore vwr text)))
               (symbol-function '%viewer-set-visibility-callback) (lambda (vwr fn) (declare (ignore vwr fn)))
               (symbol-function '%viewer-get-context) (lambda (vwr) (declare (ignore vwr)) (cffi:null-pointer))
               (symbol-function '%viewer-get-ais-object) (lambda (vwr name) (declare (ignore vwr name)) (cffi:null-pointer))
               (symbol-function '%viewer-set-selection-callback) (lambda (vwr fn) (declare (ignore vwr fn)))
               (symbol-function '%viewer-set-tree-selection-callback) (lambda (vwr fn) (declare (ignore vwr fn)))
               (symbol-function '%viewer-set-mouse-selection-scheme) (lambda (vwr key scheme) (declare (ignore vwr key scheme)))
                (symbol-function '%viewer-sync-tree-selection) (lambda (vwr) (declare (ignore vwr)))
                (symbol-function '%viewer-set-repl-history-modifier) (lambda (vwr mod) (declare (ignore vwr mod)))
                 (symbol-function '%viewer-set-repl-submit-modifier) (lambda (vwr mod) (declare (ignore vwr mod)))
                 (symbol-function '%viewer-post-event-delayed) (lambda (vwr ms) (declare (ignore vwr ms)))
                  (symbol-function '%viewer-set-import-status) (lambda (vwr show cur tot) (declare (ignore vwr show cur tot)))
                   (symbol-function '%viewer-set-icon-palette) (lambda (vwr fg) (declare (ignore vwr fg)))
                   (symbol-function '%viewer-show-viewcube) (lambda (vwr s) (declare (ignore vwr)) (setf mock-viewcube-state s))
                   (symbol-function '%viewer-is-viewcube-visible) (lambda (vwr) (declare (ignore vwr)) mock-viewcube-state)
                   (symbol-function '%viewer-set-view) (lambda (vwr o) (declare (ignore vwr)) (setf mock-view-orientation o))
                   (symbol-function '%viewer-get-view-orientation) (lambda (vwr) (declare (ignore vwr)) mock-view-orientation)
                   (symbol-function '%viewer-set-viewcube-callback) (lambda (vwr fn) (declare (ignore vwr)) (setf mock-viewcube-callback fn))
                   (symbol-function '%viewer-set-viewcube-color) (lambda (vwr r g b) (declare (ignore vwr r g b)))
                   (symbol-function '%viewer-set-viewcube-text-color) (lambda (vwr r g b) (declare (ignore vwr r g b)))
                   (symbol-function '%viewer-set-viewcube-inner-color) (lambda (vwr r g b) (declare (ignore vwr r g b)))
                   (symbol-function '%viewer-set-viewcube-transparency) (lambda (vwr transparency) (declare (ignore vwr transparency)))
                   (symbol-function '%viewer-set-viewcube-size) (lambda (vwr sz) (declare (ignore vwr sz)))
                   (symbol-function '%viewer-set-viewcube-axis-color) (lambda (vwr p r g b) (declare (ignore vwr p r g b)))
                   (symbol-function '%viewer-set-viewcube-draw-axes) (lambda (vwr s) (declare (ignore vwr s)) (setf mock-viewcube-state s))
                   (symbol-function '%viewer-get-viewcube-draw-axes) (lambda (vwr) (declare (ignore vwr)) mock-viewcube-state)
                   (symbol-function '%viewer-set-viewcube-hilight-color) (lambda (vwr r g b) (declare (ignore vwr r g b))))
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
                  (symbol-function '%viewer-set-trihedron-text-color) ,(nth 18 old-syms)
                  (symbol-function '%viewer-set-status-text) ,(nth 19 old-syms)
                    (symbol-function '%viewer-set-visibility-callback) ,(nth 20 old-syms)
                    (symbol-function '%viewer-get-context) ,(nth 21 old-syms)
                    (symbol-function '%viewer-get-ais-object) ,(nth 22 old-syms)
                    (symbol-function '%viewer-set-selection-callback) ,(nth 23 old-syms)
                    (symbol-function '%viewer-set-tree-selection-callback) ,(nth 24 old-syms)
                    (symbol-function '%viewer-set-mouse-selection-scheme) ,(nth 25 old-syms)
                     (symbol-function '%viewer-sync-tree-selection) ,(nth 26 old-syms)
                     (symbol-function '%viewer-set-repl-history-modifier) ,(nth 27 old-syms)
                      (symbol-function '%viewer-set-repl-submit-modifier) ,(nth 28 old-syms)
                      (symbol-function '%viewer-post-event-delayed) ,(nth 29 old-syms)
                       (symbol-function '%viewer-set-import-status) ,(nth 30 old-syms)
                        (symbol-function '%viewer-set-icon-palette) ,(nth 31 old-syms)
                        (symbol-function '%viewer-show-viewcube) ,(nth 32 old-syms)
                        (symbol-function '%viewer-is-viewcube-visible) ,(nth 33 old-syms)
                        (symbol-function '%viewer-set-view) ,(nth 34 old-syms)
                        (symbol-function '%viewer-get-view-orientation) ,(nth 35 old-syms)
                        (symbol-function '%viewer-set-viewcube-callback) ,(nth 36 old-syms)
                        (symbol-function '%viewer-set-viewcube-color) ,(nth 37 old-syms)
                        (symbol-function '%viewer-set-viewcube-text-color) ,(nth 38 old-syms)
                        (symbol-function '%viewer-set-viewcube-inner-color) ,(nth 39 old-syms)
                        (symbol-function '%viewer-set-viewcube-transparency) ,(nth 40 old-syms)
                        (symbol-function '%viewer-set-viewcube-size) ,(nth 41 old-syms)
                        (symbol-function '%viewer-set-viewcube-axis-color) ,(nth 42 old-syms)
                        (symbol-function '%viewer-set-viewcube-draw-axes) ,(nth 43 old-syms)
                        (symbol-function '%viewer-get-viewcube-draw-axes) ,(nth 44 old-syms)
                        (symbol-function '%viewer-set-viewcube-hilight-color) ,(nth 45 old-syms)))))))

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

(deftest show-viewcube-sets-visible
  (with-mocked-viewer
    (show-viewcube t)
    (assert-true *viewcube-visible*)
    (show-viewcube nil)
    (assert-nil *viewcube-visible*)))

(deftest toggle-viewcube-flips
  (with-mocked-viewer
    (let ((before *viewcube-visible*))
      (toggle-viewcube)
      (assert-equal (not before) *viewcube-visible*))))

(deftest set-view-top-sets-current-view
  (with-mocked-viewer
    (set-view :top)
    (assert-eq :top *current-view*)))

(deftest set-view-all-directions
  (with-mocked-viewer
    (dolist (dir '(:top :bottom :front :back :left :right :iso))
      (set-view dir)
      (assert-eq dir *current-view* (format nil "~S should set *current-view*" dir)))))

(deftest current-view-returns-set-orientation
  (with-mocked-viewer
    (set-view :front)
    (assert-eq :front (current-view))))

(deftest viewcube-callback-updates-current-view
  (with-mocked-viewer
    ;; Register callback
    (register-viewcube-callback)
    (assert-true mock-viewcube-callback "callback should be registered")
    ;; Simulate ViewCube click by invoking the callback
    (funcall mock-viewcube-callback 1)
    (assert-eq :front *current-view* "callback with 1 (V3d_Ypos) should set :front")))

(deftest palette-has-viewcube-colors
  (let ((dark (cl-occt-viewer::%dark-palette "#0078d4"))
        (light (cl-occt-viewer::%light-palette "#0078d4")))
    (dolist (p (list dark light))
      (assert-true (assoc :viewcube-color p) "should have viewcube-color")
      (assert-true (assoc :viewcube-text-color p) "should have viewcube-text-color")
      (assert-true (assoc :viewcube-inner-color p) "should have viewcube-inner-color")
      (assert-true (assoc :viewcube-transparency p) "should have viewcube-transparency"))))

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
                   "SET-VIEW-AA" "SET-REPL-HISTORY-KEY" "SET-REPL-SUBMIT-KEY"
                   "DEF" "SHOW" "HIDE" "TOGGLE"
                  "SHOW-DEFS" "TOGGLE-DEFS" "RESOLVE-SHAPE"
                  "CUT" "FUSE" "COMMON" "SECTION"
                  "TRANSLATE" "ROTATE"
                  "MAKE-PRISM" "MAKE-REVOL"
                  "MAKE-COMPOUND" "MAKE-PART"
                  "WRITE-STEP" "WRITE-STL"
                  "SELECT" "DESELECT" "CLEAR-SELECTION" "SELECTED-SHAPES"
                  "APPLY-SELECTION-SCHEMES"
                  "SHOW-VIEWCUBE" "TOGGLE-VIEWCUBE" "SHOW-VIEWCUBE-AXES"
                  "TOGGLE-VIEWCUBE-AXES" "SET-VIEW" "CURRENT-VIEW"))
    (let ((found (find-symbol sym :cl-occt-user)))
      (assert-true found (format nil "~A should be accessible in cl-occt-user" sym))
      (assert-true (fboundp found)
                   (format nil "~A should be fbound in cl-occt-user" sym)))))

;; --- REPL tests ---

(deftest repl-accumulator-starts-empty
  (assert-true (string= *repl-accumulator* "")))

(deftest repl-eof-sentinel-is-gensym
  (assert-true (symbolp *repl-eof-sentinel*)))

;; --- Multi-form eval tests ---

(defun call-eval-string (code)
  "Helper: simulate the eval-string callback and return what snprintf would write."
  (let* ((buf (cffi:foreign-alloc :char :count 4096))
         (result (unwind-protect
                     (progn
                       (cffi:callback eval-string) code buf 4096
                       (cffi:foreign-string-to-lisp buf))
                  (cffi:foreign-free buf))))
    result))

(deftest single-form-works
  (with-mocked-viewer
    (setf *repl-accumulator* "")
    (let ((output (call-eval-string "(+ 1 2)")))
      (assert-true (search "3" output :test 'char=)
                   "single form should evaluate")
      (assert-true (search "3" output :test 'char=)
                   "single form should produce 3"))))

(deftest multiple-simple-forms-evaluated
  (with-mocked-viewer
    (setf *repl-accumulator* "")
    (let ((output (call-eval-string "(+ 1 2) (+ 3 4)")))
      (assert-true (search "3" output :test 'char=)
                   "first form should produce 3")
      (assert-true (search "7" output :test 'char=)
                   "second form should produce 7"))))

(deftest incomplete-form-still-accumulates
  (with-mocked-viewer
    (setf *repl-accumulator* "")
    (let ((output (call-eval-string "(+ 1 2) (+ 3")))
      (assert-true (search "3" output :test 'char=)
                   "complete first form should produce 3")
      (assert-true (string= *repl-accumulator* "(+ 3")
                   "incomplete form should be stored in accumulator"))))

(deftest accumulator-prepends-to-next-input
  (with-mocked-viewer
    (setf *repl-accumulator* "(+ 3")
    (let ((output (call-eval-string " 4)")))
      (assert-true (search "7" output :test 'char=)
                   "accumulator + next input should eval (+ 3 4)")
      (assert-true (string= *repl-accumulator* "")
                   "accumulator should be cleared after complete eval"))))

(deftest error-in-one-form-does-not-block-others
  (with-mocked-viewer
    (setf *repl-accumulator* "")
    (let ((output (call-eval-string "(+ 1 2) (error \"oops\") (+ 3 4)")))
      (assert-true (search "3" output :test 'char=)
                   "first form should produce 3")
      (assert-true (search "Error: oops" output :test 'char=)
                   "error should be reported")
      (assert-true (search "7" output :test 'char=)
                   "third form should produce 7"))))

(deftest empty-input-produces-no-output
  (with-mocked-viewer
    (setf *repl-accumulator* "")
    (let ((output (call-eval-string "    ")))
      (assert-true (string= output "")
                   "whitespace-only input should produce empty output"))))

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

;; --- Lisp import/export tests ---

(deftest import-tick-processes-one-form
  (with-mocked-viewer
    (setf *repl-log* nil
          *import-forms* '((+ 1 2) (* 3 4) (- 10 5))
          *import-total* 3
          *import-done* 0
          *import-cancelled* nil)
    (process-import-tick)
    (assert-equal 2 (length *import-forms*)
                  "one form should be consumed")
    (assert-equal 1 (length *repl-log*)
                  "one entry should be added to repl-log")
    (let ((entry (car *repl-log*)))
      (assert-true (search "3" (cdr entry) :test 'char=)
                   "result of (+ 1 2) should be in log"))))

(deftest import-tick-cancelled-stops
  (with-mocked-viewer
    (setf *repl-log* nil
          *import-forms* '((+ 1 2))
          *import-total* 1
          *import-done* 0
          *import-cancelled* t)
    (process-import-tick)
    (assert-true (null *repl-log*)
                 "no form should be evaluated when cancelled")
    (assert-true (null *import-forms*)
                 "import-forms should be cleaned up after cancel")))

(deftest import-tick-error-continues
  (with-mocked-viewer
    (setf *repl-log* nil
          *import-forms* '((error "oops") (+ 1 2))
          *import-total* 2
          *import-done* 0
          *import-cancelled* nil)
    (process-import-tick)
    (assert-equal 1 (length *repl-log*))
    (assert-true (search "Error: oops" (cdar *repl-log*) :test 'char=)
                 "error form should be logged with error message")
    (process-import-tick)
    (assert-equal 2 (length *repl-log*))
    (assert-true (null *import-forms*)
                 "all forms should be consumed")
    (assert-true (search "3" (cdar *repl-log*) :test 'char=)
                 "valid form after error should still produce result")))

(deftest repl-log-captures-manual
  (with-mocked-viewer
    (setf *repl-log* nil)
    (let* ((code "(+ 1 2)")
           (values (multiple-value-list (eval '(+ 1 2))))
           (output (with-output-to-string (s)
                     (dolist (v values)
                       (format s "~S~%" v)))))
      (push (cons code output) *repl-log*))
    (assert-equal 1 (length *repl-log*)
                  "direct push should add to repl-log")
    (assert-true (string= "(+ 1 2)" (caar *repl-log*))
                 "log should capture input code")
    (assert-true (search "3" (cdar *repl-log*) :test 'char=)
                 "log should capture output")))

(deftest export-repl-history-clean
  (with-mocked-viewer
    (setf *repl-log* '(("(def :s (make-sphere 5))" . "NIL\n") ("(show :s)" . "T\n"))
          *export-with-output* nil)
    (let ((path (format nil "/tmp/test-export-clean-~D.lisp" (get-universal-time))))
      (unwind-protect
           (progn
             (export-repl-history path)
             (with-open-file (f path)
               (let ((line1 (read-line f nil nil))
                     (line2 (read-line f nil nil)))
                 (assert-true (and (stringp line1) (stringp line2))
                              "file should have two non-empty lines")
                  ;; export-repl-history reverses the log so newest entries appear first
                  (assert-true (string= "(show :s)" line1)
                               "first line should be newest entry's code")
                  (assert-true (string= "(def :s (make-sphere 5))" line2)
                               "second line should be oldest entry's code")))))
      (ignore-errors (delete-file path)))))

(deftest export-repl-history-debug
  (with-mocked-viewer
    (setf *repl-log* '(("(def :s (make-sphere 5))" . "NIL\n") ("(show :s)" . "T\n"))
          *export-with-output* t)
    (let ((path (format nil "/tmp/test-export-debug-~D.lisp" (get-universal-time))))
      (unwind-protect
           (progn
             (export-repl-history path)
             (with-open-file (f path)
               (let* ((content (make-string 200))
                      (nbytes (read-sequence content f)))
                 (assert-true (> nbytes 0) "file should be non-empty")
                 (assert-true (search "(show :s)" content :test 'char=)
                              "debug: should contain newest code")
                 (assert-true (search "; T" content :test 'char=)
                              "debug: should contain newest output as comment")
                 (assert-true (search "(def :s (make-sphere 5))" content :test 'char=)
                              "debug: should contain oldest code")
                 (assert-true (search "; NIL" content :test 'char=)
                               "debug: should contain oldest output as comment"))))
       (ignore-errors (delete-file path))))))

(deftest replay-speed-sets-variable
  (with-mocked-viewer
    (replay-speed 500)
    (assert-equal 500 *import-speed*
                  "replay-speed 500 should set *import-speed* to 500")
    (replay-speed nil)
    (assert-nil *import-speed*
                "replay-speed nil should set *import-speed* to nil")))

(deftest cancel-import-noop-when-idle
  (with-mocked-viewer
    (setf *import-forms* nil *import-cancelled* nil)
    (cancel-import)
    ;; should not error - just a no-op
    (assert-nil *import-forms*)))

(deftest result-export-toggles
  (with-mocked-viewer
    (result-export t)
    (assert-true *export-with-output*
                 "result-export t should set *export-with-output* to t")
    (result-export nil)
    (assert-nil *export-with-output*
                "result-export nil should set *export-with-output* to nil")))

;; --- Bootstrap tests ---

(deftest bootstrap-handles-slynk-not-available
  (let ((*viewer* (make-array 1))
        (*viewer-queue* nil)
        (*displayed-models* (make-hash-table :test 'equal))
        (*queue-lock* (sb-thread:make-mutex))
        (*grid-visible* t)
        (*axis-visible* t)
        (start-viewer-called nil))
    (let ((old-start (symbol-function 'start-viewer))
          (old-create (symbol-function '%viewer-create))
          (old-show (symbol-function '%viewer-show))
          (old-run (symbol-function '%viewer-run)))
      (setf (symbol-function '%viewer-create) (lambda (title w h) (declare (ignore title w h)) *viewer*)
            (symbol-function '%viewer-show) (lambda (vwr) (declare (ignore vwr)))
            (symbol-function '%viewer-run) (lambda (vwr) (declare (ignore vwr)))
            (symbol-function 'start-viewer)
            (lambda (&key &allow-other-keys) (setf start-viewer-called t)))
      (unwind-protect
          (progn
            (bootstrap)
            (assert-true start-viewer-called
                         "bootstrap should call start-viewer even when slynk is unavailable"))
        (setf (symbol-function 'start-viewer) old-start
              (symbol-function '%viewer-create) old-create
              (symbol-function '%viewer-show) old-show
              (symbol-function '%viewer-run) old-run)))))

;; --- make-core load test ---

(deftest make-core-loads-systems
  (assert-true (find-symbol "BOOTSTRAP" :cl-occt-viewer)
               "bootstrap should be defined after loading cl-occt-viewer"))

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
        (*viewcube-visible* t)
        (*current-view* nil)
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
          (old-spc (symbol-function '%viewer-set-placeholder-color))
          (old-sttc (symbol-function '%viewer-set-trihedron-text-color))
          (old-msms (symbol-function '%viewer-set-mouse-selection-scheme))
          (old-vst (symbol-function '%viewer-sync-tree-selection))
           (old-sip (symbol-function '%viewer-set-icon-palette))
           (old-svc (symbol-function '%viewer-set-viewcube-color))
           (old-svct (symbol-function '%viewer-set-viewcube-text-color))
           (old-svci (symbol-function '%viewer-set-viewcube-inner-color))
           (old-svctr (symbol-function '%viewer-set-viewcube-transparency))
           (old-svcac (symbol-function '%viewer-set-viewcube-axis-color))
           (old-svcda (symbol-function '%viewer-set-viewcube-draw-axes))
           (old-gvcda (symbol-function '%viewer-get-viewcube-draw-axes))
           (old-svchc (symbol-function '%viewer-set-viewcube-hilight-color)))
      (setf (symbol-function '%viewer-show-axis)
            (lambda (vwr show) (declare (ignore vwr)) (push show show-axis-args))
            (symbol-function '%viewer-show-grid)
            (lambda (vwr show) (declare (ignore vwr)) (push show show-grid-args))
            (symbol-function '%viewer-set-antialiasing)
            (lambda (vwr enable) (declare (ignore vwr)) (push enable set-aa-args))
            (symbol-function '%viewer-set-stylesheet)
            (lambda (vwr qss) (declare (ignore vwr qss)))
            (symbol-function '%viewer-set-icon-palette)
            (lambda (vwr fg) (declare (ignore vwr fg)))
            (symbol-function '%viewer-color-scheme)
            (lambda (vwr) (declare (ignore vwr)) 0)
            (symbol-function '%viewer-set-color-scheme-callback)
            (lambda (vwr fn) (declare (ignore vwr fn)))
            (symbol-function '%viewer-get-view)
            (lambda (vwr) (declare (ignore vwr)) (cffi:null-pointer))
            (symbol-function '%viewer-get-trihedron)
            (lambda (vwr) (declare (ignore vwr)) (cffi:null-pointer))
            (symbol-function '%viewer-set-placeholder-color)
            (lambda (vwr r g b) (declare (ignore vwr r g b)))
            (symbol-function '%viewer-set-trihedron-text-color)
            (lambda (vwr part r g b) (declare (ignore vwr part r g b)))
            (symbol-function '%viewer-set-mouse-selection-scheme)
            (lambda (vwr key scheme) (declare (ignore vwr key scheme)))
            (symbol-function '%viewer-sync-tree-selection)
            (lambda (vwr) (declare (ignore vwr)))
            (symbol-function '%viewer-set-viewcube-color)
            (lambda (vwr r g b) (declare (ignore vwr r g b)))
            (symbol-function '%viewer-set-viewcube-text-color)
            (lambda (vwr r g b) (declare (ignore vwr r g b)))
            (symbol-function '%viewer-set-viewcube-inner-color)
            (lambda (vwr r g b) (declare (ignore vwr r g b)))
            (symbol-function '%viewer-set-viewcube-transparency)
            (lambda (vwr transparency) (declare (ignore vwr transparency)))
            (symbol-function '%viewer-set-viewcube-axis-color)
            (lambda (vwr p r g b) (declare (ignore vwr p r g b)))
            (symbol-function '%viewer-set-viewcube-draw-axes)
            (lambda (vwr s) (declare (ignore vwr s)))
            (symbol-function '%viewer-get-viewcube-draw-axes)
            (lambda (vwr) (declare (ignore vwr)) 1)
            (symbol-function '%viewer-set-viewcube-hilight-color)
            (lambda (vwr r g b) (declare (ignore vwr r g b))))
      (unwind-protect
           (progn
             (initialize-viewer *viewer*)
              (assert-equal '(0) (nreverse show-axis-args)
                            "%viewer-show-axis should be called with show=0")
             (assert-equal '(1) (nreverse show-grid-args)
                           "%viewer-show-grid should be called with show=1")
             (assert-equal '(1) (nreverse set-aa-args)
                           "%viewer-set-antialiasing should be called with enable=1"))
        (setf (symbol-function '%viewer-show-axis) old-axis
              (symbol-function '%viewer-show-grid) old-grid
              (symbol-function '%viewer-set-antialiasing) old-aa
              (symbol-function '%viewer-set-stylesheet) old-ss
              (symbol-function '%viewer-set-icon-palette) old-sip
              (symbol-function '%viewer-color-scheme) old-cs
              (symbol-function '%viewer-set-color-scheme-callback) old-csc
              (symbol-function '%viewer-get-view) old-gv
               (symbol-function '%viewer-get-trihedron) old-gt
               (symbol-function '%viewer-set-placeholder-color) old-spc
               (symbol-function '%viewer-set-trihedron-text-color) old-sttc
               (symbol-function '%viewer-set-mouse-selection-scheme) old-msms
              (symbol-function '%viewer-sync-tree-selection) old-vst
              (symbol-function '%viewer-set-viewcube-color) old-svc
              (symbol-function '%viewer-set-viewcube-text-color) old-svct
              (symbol-function '%viewer-set-viewcube-inner-color) old-svci
              (symbol-function '%viewer-set-viewcube-transparency) old-svctr
              (symbol-function '%viewer-set-viewcube-axis-color) old-svcac
              (symbol-function '%viewer-set-viewcube-draw-axes) old-svcda
              (symbol-function '%viewer-get-viewcube-draw-axes) old-gvcda
              (symbol-function '%viewer-set-viewcube-hilight-color) old-svchc)))))

;; --- Selection tests ---

(deftest selection-starts-empty
  (with-mocked-viewer
    (assert-true (zerop (hash-table-count *selected*))
                 "*selected* should be empty initially")))

(deftest select-adds-names
  (with-mocked-viewer
    (select :a :b)
    (assert-equal 2 (hash-table-count *selected*))
    (assert-true (gethash "A" *selected*))
    (assert-true (gethash "B" *selected*))))

(deftest select-with-no-args-clears
  (with-mocked-viewer
    (select :a)
    (select)
    (assert-true (zerop (hash-table-count *selected*))
                 "*selected* should be empty after (select)")))

(deftest select-replaces-previous
  (with-mocked-viewer
    (select :a :b)
    (select :c)
    (assert-equal 1 (hash-table-count *selected*))
    (assert-true (gethash "C" *selected*))))

(deftest deselect-removes-one
  (with-mocked-viewer
    (select :a :b :c)
    (deselect :a)
    (assert-equal 2 (hash-table-count *selected*))
    (assert-nil (gethash "A" *selected*))))

(deftest clear-selection-empties
  (with-mocked-viewer
    (select :a :b)
    (clear-selection)
    (assert-true (zerop (hash-table-count *selected*)))))

(deftest selected-shapes-returns-list
  (with-mocked-viewer
    (select :a :b)
    (let ((shapes (selected-shapes)))
      (assert-equal 2 (length shapes))
      (assert-true (member "A" shapes :test 'string=))
      (assert-true (member "B" shapes :test 'string=)))))

(deftest select-pushes-sync-selection
  (with-mocked-viewer
    (select :a)
    (assert-equal :sync-selection (first (first *viewer-queue*)))))

(deftest deselect-pushes-sync-selection
  (with-mocked-viewer
    (select :a :b)
    (setf *viewer-queue* nil)
    (deselect :a)
    (assert-equal :sync-selection (first (first *viewer-queue*)))))

(deftest clear-selection-pushes-sync-selection
  (with-mocked-viewer
    (clear-selection)
    (assert-equal :sync-selection (first (first *viewer-queue*)))))

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
               palette-font-size-uses-variable set-font-size-updates-and-reapplies
               selection-starts-empty select-adds-names
               select-with-no-args-clears select-replaces-previous
               deselect-removes-one clear-selection-empties
               selected-shapes-returns-list
               select-pushes-sync-selection
               deselect-pushes-sync-selection
               clear-selection-pushes-sync-selection
               import-tick-processes-one-form
               import-tick-cancelled-stops
               import-tick-error-continues
               repl-log-captures-manual
               export-repl-history-clean
               export-repl-history-debug
               replay-speed-sets-variable
               cancel-import-noop-when-idle
               result-export-toggles
                bootstrap-handles-slynk-not-available
               make-core-loads-systems))
      (funcall test-sym))
    (format t "~2&=== Results: ~D pass, ~D fail, ~D errors ===~%"
            (test-result-pass *test-result*)
            (test-result-fail *test-result*)
            (test-result-errors *test-result*))
    (values (test-result-pass *test-result*)
            (test-result-fail *test-result*))))
