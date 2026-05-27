(in-package :clotcad)

;; ─── Test shapes ───

(defun %naming-test-box ()
  (cl-occt:make-box 10 20 30))

(defun %naming-test-cylinder ()
  (cl-occt:make-cylinder 5 20))

;; ─── name-subshape tests ───

(deftest name-subshape-stores-query
  (with-clean-registry
    (let ((shape (%naming-test-box)))
      (register-model "my-box" (make-model :name "my-box" :cached-shape shape))
      (let ((result (name-subshape :my-box :top-face
                      :where (list (face-p) (normal-along 0 0 1) (max-by #'z-center)))))
        (assert-eq :top-face result)
        (let ((m (find-model "my-box")))
          (assert-true m)
          (let ((ns (model-named-subshapes m)))
            (assert-equal 1 (length ns))
            (assert-eq :top-face (caar ns))))))))

(deftest name-subshape-errors-on-unknown-model
  (with-clean-registry
    (assert-error
      (name-subshape :nonexistent :top-face
        :where (list (face-p))))))

(deftest name-subshape-overwrites-existing
  (with-clean-registry
    (let ((shape (%naming-test-box)))
      (register-model "my-box" (make-model :name "my-box" :cached-shape shape))
      (name-subshape :my-box :top-face
        :where (list (face-p) (normal-along 0 0 1)))
      (name-subshape :my-box :top-face
        :where (list (face-p) (normal-along 0 0 -1)))
      (let ((m (find-model "my-box")))
        (assert-equal 1 (length (model-named-subshapes m)))
        (let* ((entry (assoc :top-face (model-named-subshapes m) :test #'eq))
               (plist (cdr entry)))
          (assert-true (member :where plist))
          (assert-true (member (list (face-p) (normal-along 0 0 -1)) plist)))))))

(deftest name-subshape-accepts-string-name
  (with-clean-registry
    (let ((shape (%naming-test-box)))
      (register-model "my-box" (make-model :name "my-box" :cached-shape shape))
      (name-subshape "my-box" "top-face"
        :where (list (face-p) (normal-along 0 0 1)))
      (let ((m (find-model "my-box")))
        (assert-true (assoc :top-face (model-named-subshapes m) :test #'eq))))))

;; ─── face-ref / edge-ref / vertex-ref tests ───

(deftest face-ref-returns-face
  (with-clean-registry
    (let ((shape (%naming-test-box)))
      (register-model "my-box" (make-model :name "my-box" :cached-shape shape))
      (name-subshape :my-box :top-face
        :where (list (face-p) (normal-along 0 0 1) (max-by #'z-center)))
      (let ((face (face-ref :my-box :top-face)))
        (assert-true face)
        (assert-eq :face (cl-occt:shape-type face))))))

(deftest edge-ref-returns-edge
  (with-clean-registry
    (let ((shape (%naming-test-box)))
      (register-model "my-box" (make-model :name "my-box" :cached-shape shape))
      (name-subshape :my-box :longest
        :where (list (edge-p) (max-by #'cl-occt:edge-length)))
      (let ((edge (edge-ref :my-box :longest)))
        (assert-true edge)
        (assert-eq :edge (cl-occt:shape-type edge))))))

(deftest vertex-ref-returns-vertex
  (with-clean-registry
    (let ((shape (%naming-test-box)))
      (register-model "my-box" (make-model :name "my-box" :cached-shape shape))
      (name-subshape :my-box :corner
        :where (list (vertex-p) (x-center 0) (y-center 0) (z-center 0)))
      (let ((vertex (vertex-ref :my-box :corner)))
        (assert-true vertex)
        (assert-eq :vertex (cl-occt:shape-type vertex))))))

(deftest face-ref-errors-on-unknown-name
  (with-clean-registry
    (let ((shape (%naming-test-box)))
      (register-model "my-box" (make-model :name "my-box" :cached-shape shape))
      (assert-error (face-ref :my-box :nonexistent)))))

(deftest face-ref-errors-on-type-mismatch
  (with-clean-registry
    (let ((shape (%naming-test-box)))
      (register-model "my-box" (make-model :name "my-box" :cached-shape shape))
      (name-subshape :my-box :an-edge
        :where (list (edge-p) (max-by #'cl-occt:edge-length)))
      (assert-error (face-ref :my-box :an-edge)))))

(deftest face-ref-errors-on-unknown-model
  (with-clean-registry
    (assert-error (face-ref :unknown :anything))))

;; ─── list-named-subshapes tests ───

(deftest list-named-subshapes-returns-names
  (with-clean-registry
    (let ((shape (%naming-test-box)))
      (register-model "my-box" (make-model :name "my-box" :cached-shape shape))
      (name-subshape :my-box :top-face
        :where (list (face-p) (normal-along 0 0 1)))
      (name-subshape :my-box :longest-edge
        :where (list (edge-p) (max-by #'cl-occt:edge-length)))
      (let ((names (list-named-subshapes :my-box)))
        (assert-equal 2 (length names))
        (assert-true (member :top-face names))
        (assert-true (member :longest-edge names))))))

(deftest list-named-subshapes-empty-when-none
  (with-clean-registry
    (let ((shape (%naming-test-box)))
      (register-model "my-box" (make-model :name "my-box" :cached-shape shape))
      (assert-equal nil (list-named-subshapes :my-box)))))

(deftest list-named-subshapes-errors-on-unknown-model
  (with-clean-registry
    (assert-error (list-named-subshapes :unknown))))

;; ─── remove-named-subshape tests ───

(deftest remove-named-subshape-removes
  (with-clean-registry
    (let ((shape (%naming-test-box)))
      (register-model "my-box" (make-model :name "my-box" :cached-shape shape))
      (name-subshape :my-box :top-face
        :where (list (face-p) (normal-along 0 0 1)))
      (assert-equal 1 (length (list-named-subshapes :my-box)))
      (remove-named-subshape :my-box :top-face)
      (assert-equal 0 (length (list-named-subshapes :my-box)))
      (assert-error (face-ref :my-box :top-face)))))

(deftest remove-named-subshape-errors-on-unknown
  (with-clean-registry
    (let ((shape (%naming-test-box)))
      (register-model "my-box" (make-model :name "my-box" :cached-shape shape))
      (assert-error (remove-named-subshape :my-box :nonexistent)))))

;; ─── defmodel recomputation test ───

(deftest named-subshape-survives-defmodel-recompute
  (with-clean-registry
    (defmodel my-box (:w :h)
      (make-box (param :w) (param :h) 30))
    (set-params! :w 10 :h 20)
    (name-subshape :my-box :top-face
      :where (list (face-p) (normal-along 0 0 1) (max-by #'z-center)))
    ;; resolve before recomputation
    (let ((before (face-ref :my-box :top-face)))
      (assert-true before)
      (assert-eq :face (cl-occt:shape-type before)))
    ;; trigger recomputation via parameter change
    (set-param! :w 30)
    ;; should still resolve on new shape
    (let ((after (face-ref :my-box :top-face)))
      (assert-true after)
      (assert-eq :face (cl-occt:shape-type after)))))

;; ─── propagate-named-subshapes tests ───

(deftest propagate-named-subshapes-clears-cache
  (with-clean-registry
    (let ((shape (%naming-test-box)))
      (register-model "my-box" (make-model :name "my-box" :cached-shape shape))
      (setf (model-named-subshape-cache (find-model "my-box"))
            '((:top-face . "cached")))
      (propagate-named-subshapes "my-box")
      (let ((m (find-model "my-box")))
        (assert-nil (model-named-subshape-cache m))))))

;; ─── Compound symbol resolution tests ───

(deftest parse-compound-symbol-splits
  (with-clean-registry
    (multiple-value-bind (model-name subshape-name)
        (clotcad::%parse-compound-symbol :my-box/top-face)
      (assert-eq :my-box model-name)
      (assert-eq :top-face subshape-name))))

(deftest parse-compound-symbol-returns-nil-for-plain
  (with-clean-registry
    (assert-nil (clotcad::%parse-compound-symbol :my-box))))

(deftest parse-compound-symbol-handles-multiple-slashes
  (with-clean-registry
    (multiple-value-bind (model-name subshape-name)
        (clotcad::%parse-compound-symbol :a/b/c)
      (assert-eq :a model-name)
      (assert-eq :b/c subshape-name))))

(deftest resolve-compound-symbol-resolves-via-face-ref
  (with-clean-registry
    (let ((shape (%naming-test-box)))
      (register-model "my-box" (make-model :name "my-box" :cached-shape shape))
      (name-subshape :my-box :top-face
        :where (list (face-p) (normal-along 0 0 1) (max-by #'z-center)))
      (let ((result (clotcad::%resolve-compound-symbol :my-box/top-face)))
        (assert-true result)
        (assert-eq :face (cl-occt:shape-type result))))))

(deftest resolve-compound-symbol-returns-nil-for-plain
  (with-clean-registry
    (assert-nil (clotcad::%resolve-compound-symbol :my-box))))

(deftest resolve-compound-symbol-errors-on-unknown-model
  (with-clean-registry
    (assert-error (clotcad::%resolve-compound-symbol :unknown/face))))

;; ─── resolve-shape with compound symbol ───

(deftest resolve-shape-handles-compound-symbol
  (with-clean-registry
    (let ((shape (%naming-test-box)))
      (register-model "my-box" (make-model :name "my-box" :cached-shape shape))
      (name-subshape :my-box :top-face
        :where (list (face-p) (normal-along 0 0 1) (max-by #'z-center)))
      (let ((result (resolve-shape :my-box/top-face)))
        (assert-true result)
        (assert-eq :face (cl-occt:shape-type result))))))

(deftest resolve-shape-still-resolves-plain-symbols
  (with-clean-registry
    (let ((shape (%naming-test-box)))
      (register-model "my-box" (make-model :name "my-box" :cached-shape shape))
      (let ((result (resolve-shape :my-box)))
        (assert-true result)))))

;; ─── Named subshape survives model recomputation ───

(deftest named-subshape-survives-recomputation
  (with-clean-registry
    (let ((shape (%naming-test-box)))
      (register-model "my-box" (make-model :name "my-box" :cached-shape shape))
      (name-subshape :my-box :top-face
        :where (list (face-p) (normal-along 0 0 1) (max-by #'z-center)))
      ;; Simulate recomputation: update cached shape and clear cache
      (let ((new-shape (%naming-test-box)))
        (setf (model-cached-shape (find-model "my-box")) new-shape)
        (propagate-named-subshapes "my-box"))
      ;; Named subshape should still resolve on the new shape
      (let ((face (face-ref :my-box :top-face)))
        (assert-true face)
        (assert-eq :face (cl-occt:shape-type face))))))

;; ─── Package availability tests ───

(deftest name-subshape-exported-from-clotcad
  (assert-eq :external
             (nth-value 1 (find-symbol "NAME-SUBSHAPE" :clotcad))))

(deftest face-ref-exported-from-clotcad
  (assert-eq :external
             (nth-value 1 (find-symbol "FACE-REF" :clotcad))))

(deftest edge-ref-exported-from-clotcad
  (assert-eq :external
             (nth-value 1 (find-symbol "EDGE-REF" :clotcad))))

(deftest vertex-ref-exported-from-clotcad
  (assert-eq :external
             (nth-value 1 (find-symbol "VERTEX-REF" :clotcad))))

(deftest list-named-subshapes-exported-from-clotcad
  (assert-eq :external
             (nth-value 1 (find-symbol "LIST-NAMED-SUBSHAPES" :clotcad))))

(deftest remove-named-subshape-exported-from-clotcad
  (assert-eq :external
             (nth-value 1 (find-symbol "REMOVE-NAMED-SUBSHAPE" :clotcad))))

(deftest naming-functions-available-in-clotcad-user
  (dolist (sym '("NAME-SUBSHAPE" "FACE-REF" "EDGE-REF" "VERTEX-REF"
                 "LIST-NAMED-SUBSHAPES" "REMOVE-NAMED-SUBSHAPE"))
    (let ((found (find-symbol sym :clotcad-user)))
      (assert-true found (format nil "~A should be accessible in clotcad-user" sym))
      (assert-true (fboundp found)
                   (format nil "~A should be fbound in clotcad-user" sym)))))
