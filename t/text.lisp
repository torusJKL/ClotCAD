(in-package :clotcad)

;; ─── Font fallback tests ───

(deftest font-fallback-finds-at-least-one-font
  (let ((font (%resolve-font-with-fallback 10)))
    (assert-true (cl-occt:brep-font-p font)
                 "should find at least one fallback font")))

(deftest font-fallback-specific-font
  (let ((font (%resolve-font "sans-serif" 10)))
    (assert-true (or (null font)
                     (cl-occt:brep-font-p font))
                 "specific font name should return brep-font or nil")))

(deftest font-fallback-copes-with-missing-names
  (let ((font (%resolve-font "nonexistent-font-xyz" 10)))
    (assert-true (or (null font)
                     (cl-occt:brep-font-p font))
                 "should handle missing font name (OCCT may auto-fallback)")))

;; ─── Plane mapping tests ───

(deftest plane-keyword-xz
  (multiple-value-bind (pos normal x-dir) (%plane->values :xz)
    (assert-equal '(0 0 0) pos "xz plane origin should be (0,0,0)")
    (assert-equal '(0 1 0) normal "xz plane normal should be (0,1,0)")
    (assert-equal '(1 0 0) x-dir "xz plane x-direction should be (1,0,0)")))

(deftest plane-keyword-xy
  (multiple-value-bind (pos normal x-dir) (%plane->values :xy)
    (assert-equal '(0 0 0) pos "xy plane origin should be (0,0,0)")
    (assert-equal '(0 0 1) normal "xy plane normal should be (0,0,1)")
    (assert-equal '(1 0 0) x-dir "xy plane x-direction should be (1,0,0)")))

(deftest plane-keyword-yz
  (multiple-value-bind (pos normal x-dir) (%plane->values :yz)
    (assert-equal '(0 0 0) pos "yz plane origin should be (0,0,0)")
    (assert-equal '(1 0 0) normal "yz plane normal should be (1,0,0)")
    (assert-equal '(0 1 0) x-dir "yz plane x-direction should be (0,1,0)")))

(deftest plane-frame-passes-through
  (let ((f (make-instance 'frame
             :origin '(10 20 30)
             :x-axis '(1 0 0)
             :y-axis '(0 1 0)
             :z-axis '(0 0 1))))
    (multiple-value-bind (pos normal x-dir) (%plane->values f)
      (assert-equal '(10 20 30) pos "frame origin should pass through")
      (assert-equal '(0 0 1) normal "frame z-axis should become normal")
      (assert-equal '(1 0 0) x-dir "frame x-axis should become x-direction"))))

(deftest plane-face-uses-make-frame-on-face
  (let* ((box (cl-occt:make-box 10 20 30))
         (top (top-face box)))
    (multiple-value-bind (pos normal x-dir) (%plane->values top)
      (assert-true (and pos normal x-dir) "face plane should return three values")
      (let ((f (make-frame-on-face top)))
        (assert-equal (frame-origin f) pos "origin should match frame")
        (assert-equal (frame-z-axis f) normal "normal should match frame z-axis")
        (assert-equal (frame-x-axis f) x-dir "x-direction should match frame x-axis")))))

(deftest plane-invalid-signals-error
  (assert-error (%plane->values :invalid-plane))
  "invalid plane keyword should signal an error")

;; ─── Integration tests ───

(deftest make-3d-text-returns-shape
  (let ((shape (make-3d-text "Test" :size 10 :thickness 3)))
    (assert-true (cl-occt:shape-p shape)
                 "make-3d-text should return a shape")))

(deftest make-3d-text-with-font-returns-shape
  (let ((shape (make-3d-text "Test" :font "sans-serif" :size 10 :thickness 3)))
    (assert-true (cl-occt:shape-p shape)
                 "make-3d-text with explicit font should return a shape")))

(deftest make-3d-text-on-xy-plane
  (let ((shape (make-3d-text "Test" :size 10 :thickness 3 :plane :xy)))
    (assert-true (cl-occt:shape-p shape)
                 "make-3d-text on XY plane should return a shape")))

(deftest make-3d-text-on-yz-plane
  (let ((shape (make-3d-text "Test" :size 10 :thickness 3 :plane :yz)))
    (assert-true (cl-occt:shape-p shape)
                 "make-3d-text on YZ plane should return a shape")))

(deftest make-3d-text-with-face-plane
  (let* ((box (cl-occt:make-box 10 20 30))
         (top (top-face box))
         (shape (make-3d-text "Test" :size 5 :thickness 2 :plane top)))
    (assert-true (cl-occt:shape-p shape)
                 "make-3d-text on a face should return a shape")))

(deftest make-3d-text-with-frame-plane
  (let* ((f (make-instance 'frame
              :origin '(5 10 15)
              :x-axis '(1 0 0)
              :y-axis '(0 1 0)
              :z-axis '(0 0 1)))
         (shape (make-3d-text "Test" :size 5 :thickness 2 :plane f)))
    (assert-true (cl-occt:shape-p shape)
                 "make-3d-text on a frame should return a shape")))

(deftest make-3d-text-with-halign-valign
  (let ((shape (make-3d-text "Test" :size 10 :thickness 3
                             :h-align :left :v-align :bottom)))
    (assert-true (cl-occt:shape-p shape)
                 "make-3d-text with custom alignment should return a shape")))
