(in-package :clotcad)

;; ─── Planar face tests ───

(deftest make-frame-on-face-planar-box-top
  (let* ((box (cl-occt:make-box 10 20 30))
         (top (top-face box))
         (f (make-frame-on-face top)))
    (assert-true (typep f 'frame) "should return a frame")
    (multiple-value-bind (cx cy cz) (cl-occt:face-center top)
      (let ((o (frame-origin f)))
        (assert-equal (list cx cy cz) o "origin should match face center")))))

(deftest make-frame-on-face-planar-box-left
  (let* ((box (cl-occt:make-box 10 20 30))
         (faces (cl-occt:map-shape-subshapes box :face))
         (left-face (first (query-shape box
                                        :where (list (face-p) (surface-type :plane)
                                                     (normal-along -1 0 0)))))
         (f (make-frame-on-face left-face)))
    (assert-true (typep f 'frame) "should return a frame")
    ;; Z-axis should be (-1 0 0) for left face
    (let ((z (frame-z-axis f)))
      (assert-equal '(-1.0d0 0.0d0 0.0d0) z "z-axis should be -X direction"))))

(deftest make-frame-on-face-at-uv
  (let* ((box (cl-occt:make-box 10 20 30))
         (top (top-face box))
         (surface (cl-occt:face-surface top))
         (f (make-frame-on-face top :u 0.0d0 :v 0.0d0)))
    (assert-true (typep f 'frame) "should return a frame")
    (multiple-value-bind (sx sy sz) (cl-occt:surface-value surface 0.0d0 0.0d0)
      (let ((o (frame-origin f)))
        (assert-equal (list sx sy sz) o
                      "origin should match surface value at (0,0)")))))

(deftest make-frame-on-face-at-point
  (let* ((box (cl-occt:make-box 10 20 30))
         (top (top-face box))
         (f (make-frame-on-face top :point '(5.0d0 10.0d0 30.0d0))))
    (assert-true (typep f 'frame) "should return a frame")
    (let ((o (frame-origin f)))
      (assert-equal '(5.0d0 10.0d0 30.0d0) o
                    "origin should match the given point"))))

;; ─── Non-planar face tests ───

(deftest make-frame-on-face-cylinder
  (let* ((cyl (cl-occt:make-cylinder 5 20))
         (faces (cl-occt:map-shape-subshapes cyl :face))
         (cyl-faces (remove-if-not
                     (lambda (f)
                       (eq (cl-occt:face-surface-type f) :cylinder))
                     faces))
         (f (make-frame-on-face (first cyl-faces))))
    (assert-true (typep f 'frame) "should return a frame for cylindrical face")
    (let ((z (frame-z-axis f)))
      (assert-equal 3 (length z) "z-axis should be a 3-element list")
      ;; Normal should not be zero
      (assert-true (> (sqrt (reduce #'+ (mapcar (lambda (x) (* x x)) z))) 1.0d-10)
                   "normal should be non-zero"))))

(deftest make-frame-on-face-sphere
  (let* ((sphere (cl-occt:make-sphere 10))
         (faces (cl-occt:map-shape-subshapes sphere :face))
         (f (make-frame-on-face (first faces))))
    (assert-true (typep f 'frame) "should return a frame for spherical face")
    (let ((z (frame-z-axis f)))
      (assert-true (> (sqrt (reduce #'+ (mapcar (lambda (x) (* x x)) z))) 1.0d-10)
                   "normal should be non-zero"))))

(deftest make-frame-on-face-torus
  (let* ((torus (cl-occt:make-torus 20 5))
         (faces (cl-occt:map-shape-subshapes torus :face))
         (f (make-frame-on-face (first faces))))
    (assert-true (typep f 'frame) "should return a frame for toroidal face")
    (let ((z (frame-z-axis f)))
      (assert-true (> (sqrt (reduce #'+ (mapcar (lambda (x) (* x x)) z))) 1.0d-10)
                   "normal should be non-zero"))))

;; ─── Frame accessor tests ───

(deftest frame-accessors-return-correct-values
  (let* ((box (cl-occt:make-box 10 20 30))
         (top (top-face box))
         (f (make-frame-on-face top))
         (o (frame-origin f))
         (x (frame-x-axis f))
         (y (frame-y-axis f))
         (z (frame-z-axis f)))
    (assert-equal 3 (length o) "origin should be 3 elements")
    (assert-equal 3 (length x) "x-axis should be 3 elements")
    (assert-equal 3 (length y) "y-axis should be 3 elements")
    (assert-equal 3 (length z) "z-axis should be 3 elements")
    ;; Z-axis should be near (0 0 1) for top face of box
    (assert-true (every (lambda (a b) (< (abs (- a b)) 1.0d-6))
                        (frame-z-axis f)
                        '(0.0d0 0.0d0 1.0d0))
                 "z-axis should be (0 0 1) for top face of box")))

(deftest frame-accessors-right-handed
  (let* ((box (cl-occt:make-box 10 20 30))
         (top (top-face box))
         (f (make-frame-on-face top))
         (x (frame-x-axis f))
         (y (frame-y-axis f))
         (z (frame-z-axis f)))
    ;; X × Y should equal Z (right-handed)
    (let ((zx (- (* (second x) (third y)) (* (third x) (second y))))
          (zy (- (* (third x) (first y)) (* (first x) (third y))))
          (zz (- (* (first x) (second y)) (* (second x) (first y)))))
      (assert-true (every (lambda (a b) (< (abs (- a b)) 1.0d-3))
                          (list zx zy zz) z)
                   "X × Y should approximately equal Z (right-handed)"))))

;; ─── frame-to-location tests ───

(deftest frame-to-location-produces-valid-location
  (let* ((box (cl-occt:make-box 10 20 30))
         (top (top-face box))
         (f (make-frame-on-face top))
         (loc (frame-to-location f)))
    (assert-true (cffi:pointerp loc) "location should be a CFFI pointer")
    (assert-true (not (cffi:null-pointer-p loc)) "location should not be null")))

(deftest frame-to-location-moves-shape
  (let* ((box (cl-occt:make-box 10 20 30))
         (top (top-face box))
         (f (make-frame-on-face top))
         (loc (frame-to-location f))
         (sphere (cl-occt:make-sphere 5))
         (moved (cl-occt:move-shape sphere loc)))
    (assert-true (cl-occt:shape-p moved) "moved shape should be valid")
    ;; Check that the moved sphere's bounding box is near the face center
    (multiple-value-bind (cx cy cz) (cl-occt:face-center top)
      (multiple-value-bind (xmin ymin zmin xmax ymax zmax)
          (cl-occt:subshape-bounding-box moved)
        (assert-true (and xmin ymin zmin xmax ymax zmax)
                     "bounding box should not be nil")
        ;; The sphere (radius 5) centered at (cx, cy, cz) should span
        ;; [cx-5, cx+5] etc. — just check it's near the face center
        (assert-true (< (abs (- (/ (+ xmin xmax) 2) cx)) 1.0d-6)
                     "X center should match face center X")
        (assert-true (< (abs (- (/ (+ ymin ymax) 2) cy)) 1.0d-6)
                     "Y center should match face center Y")
        (assert-true (< (abs (- (/ (+ zmin zmax) 2) cz)) 1.0d-6)
                     "Z center should match face center Z")))))

;; ─── make-frame-on-plane tests ───

(deftest make-frame-on-plane-xy-plane
  (let ((f (make-frame-on-plane 0 0 0 0 0 1)))
    (assert-true (typep f 'frame) "should return a frame")
    (assert-equal '(0.0d0 0.0d0 0.0d0) (frame-origin f) "origin should be at (0,0,0)")
    (assert-equal '(0.0d0 0.0d0 1.0d0) (frame-z-axis f) "z-axis should be (0,0,1)")
    (assert-true (every (lambda (a b) (< (abs (- a b)) 1.0d-6))
                        (frame-x-axis f)
                        '(1.0d0 0.0d0 0.0d0))
                 "x-axis should be approx (1,0,0)")))

(deftest make-frame-on-plane-with-custom-up
  (let ((f (make-frame-on-plane 0 0 0 1 0 0 :up-x 0 :up-y 0 :up-z 1)))
    (assert-true (typep f 'frame) "should return a frame")
    (assert-equal '(0.0d0 0.0d0 0.0d0) (frame-origin f) "origin should be at (0,0,0)")
    (assert-equal '(1.0d0 0.0d0 0.0d0) (frame-z-axis f) "z-axis should be (1,0,0)")
    ;; With Z=(1,0,0) and UP=(0,0,1): X = cross(Z, UP) = (0,-1,0), then Y = cross(Z, X) = (0,0,1)
    ;; Actually: X = cross((1,0,0), (0,0,1)) = (0,-1,0)
    ;; Y = cross((1,0,0), (0,-1,0)) = (0,0,-1)... let me check
    ;; cross((1,0,0), (0,-1,0)) = (0*0 - 0*(-1), 0*0 - 1*0, 1*(-1) - 0*0) = (0,0,-1)
    ;; Hmm wait, that has Y pointing in -Z direction. Let me think about this differently.
    ;; 
    ;; Actually the convention in make-frame-on-plane is:
    ;; Z = normal (normalized)
    ;; X = normalize(cross(Z, UP))
    ;; Y = cross(Z, X)
    ;;
    ;; For normal=(1,0,0), UP=(0,0,1):
    ;; Z = (1,0,0)
    ;; X = cross((1,0,0), (0,0,1)) = (0*1-0*0, 0*0-1*1, 1*0-0*0) = (0,-1,0) → normalized = (0,-1,0)
    ;; Y = cross((1,0,0), (0,-1,0)) = (0*0-0*(-1), 0*0-1*0, 1*(-1)-0*0) = (0,0,-1)
    ;; So Y should be (0,0,-1)
    (assert-true (every (lambda (a b) (< (abs (- a b)) 1.0d-3))
                        (frame-y-axis f)
                        '(0.0d0 0.0d0 -1.0d0))
                 "y-axis should be approximately (0,0,-1)")))

(deftest make-frame-on-plane-offset-origin
  (let ((f (make-frame-on-plane 10 20 30 0 0 1)))
    (assert-equal '(10.0d0 20.0d0 30.0d0) (frame-origin f)
                  "origin should match specified (10,20,30)")))
