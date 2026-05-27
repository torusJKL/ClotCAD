(in-package :clotcad)

(defclass frame ()
  ((origin :initarg :origin
           :reader frame-origin)
   (x-axis :initarg :x-axis
           :reader frame-x-axis)
   (y-axis :initarg :y-axis
           :reader frame-y-axis)
   (z-axis :initarg :z-axis
           :reader frame-z-axis))
  (:documentation "A 3D coordinate frame defined by an origin and orthonormal X, Y, Z axes.

   Each axis slot contains a list of three double-float coordinates.
   The axes form a right-handed orthonormal basis.

   - **origin** list of three double-floats `(x y z)` — frame position
   - **x-axis** list of three double-floats `(dx dy dz)` — unit X direction
   - **y-axis** list of three double-floats `(dx dy dz)` — unit Y direction
   - **z-axis** list of three double-floats `(dx dy dz)` — unit Z direction

   **Returns:** a `frame` instance.

   **Example:**

       (make-instance 'frame
         :origin '(0.0d0 0.0d0 0.0d0)
         :x-axis '(1.0d0 0.0d0 0.0d0)
         :y-axis '(0.0d0 1.0d0 0.0d0)
         :z-axis '(0.0d0 0.0d0 1.0d0))

   **See also:** `make-frame-on-face`, `make-frame-on-plane`, `frame-to-location`"))

;; ─── Internal vector helpers ───

(defun %vec-sub (ax ay az bx by bz)
  (values (- ax bx) (- ay by) (- az bz)))

(defun %vec-cross (ax ay az bx by bz)
  (values (- (* ay bz) (* az by))
          (- (* az bx) (* ax bz))
          (- (* ax by) (* ay bx))))

(defun %vec-dot (ax ay az bx by bz)
  (+ (* ax bx) (* ay by) (* az bz)))

(defun %vec-len (x y z)
  (sqrt (+ (* x x) (* y y) (* z z))))

(defun %vec-normalize (x y z)
  (let ((len (%vec-len x y z)))
    (if (> len 0.0d0)
        (values (/ x len) (/ y len) (/ z len))
        (values 0.0d0 0.0d0 0.0d0))))

(defun %vec-list (x y z)
  (list x y z))

(defun %uv-midpoint (face)
  (multiple-value-bind (surface umin umax vmin vmax)
      (cl-occt:face-surface-uv-bounds face)
    (declare (ignore surface))
    (values (float (/ (+ umin umax) 2.0d0) 1.0d0)
            (float (/ (+ vmin vmax) 2.0d0) 1.0d0))))

(defun %face-normal-at-uv (face u v)
  (cl-occt:face-normal-at face (float u 1.0d0) (float v 1.0d0)))

(defun %surface-u-tangent (surface u v)
  (let* ((eps 1.0d-6)
         (u+eps (+ u eps)))
    (multiple-value-bind (x1 y1 z1) (cl-occt:surface-value surface u+eps v)
      (multiple-value-bind (x0 y0 z0) (cl-occt:surface-value surface u v)
        (if (and x1 x0)
            (%vec-normalize (- x1 x0) (- y1 y0) (- z1 z0))
            (values 1.0d0 0.0d0 0.0d0))))))

(defun %surface-v-tangent (surface u v)
  (let* ((eps 1.0d-6)
         (v+eps (+ v eps)))
    (multiple-value-bind (x1 y1 z1) (cl-occt:surface-value surface u v+eps)
      (multiple-value-bind (x0 y0 z0) (cl-occt:surface-value surface u v)
        (if (and x1 x0)
            (%vec-normalize (- x1 x0) (- y1 y0) (- z1 z0))
            (values 0.0d0 1.0d0 0.0d0))))))

;; ─── Public API ───

(defun make-frame-on-face (face &key u v point)
  "Construct a coordinate frame from a face's geometry.

   The frame origin is at the face center (or the specified UV/3D point).
   For planar faces, Z = face outward normal, X = face U-direction,
   Y = Z × X (right-handed). For non-planar faces, produces a tangent
   plane at the given point: Z = surface normal, X and Y are the
   surface UV tangent directions.

   - **face** a `shape` of type `:face`
   - **u** optional U parameter value (double-float)
   - **v** optional V parameter value (double-float)
   - **point** optional 3D list `(x y z)` — projects onto the face surface

   **Returns:** a `frame` instance with slots `origin`, `x-axis`, `y-axis`, `z-axis`.

   **Example:**

       (let* ((box (make-box 10 20 30))
              (top (top-face box)))
         (make-frame-on-face top))

       ;; At specific UV
       (make-frame-on-face top :u 0.0d0 :v 0.0d0)

       ;; At a 3D point
       (make-frame-on-face top :point '(5.0d0 10.0d0 15.0d0))

   **See also:** `make-frame-on-plane`, `frame-to-location`, `frame-origin`"
  (let* ((surface (cl-occt:face-surface face))
         (u-val 0.0d0) (v-val 0.0d0)
         (px 0.0d0) (py 0.0d0) (pz 0.0d0)
         (nz-x 0.0d0) (nz-y 0.0d0) (nz-z 0.0d0))
    ;; Determine UV parameters
    (cond
      ((and u v)
       (setf u-val (float u 1.0d0)
             v-val (float v 1.0d0)))
      (t
       (multiple-value-setq (u-val v-val) (%uv-midpoint face))))
    ;; Determine 3D point on face
    (cond
      (point
       (setf px (float (first point) 1.0d0)
             py (float (second point) 1.0d0)
             pz (float (third point) 1.0d0)))
      (surface
       (multiple-value-setq (px py pz)
         (cl-occt:surface-value surface u-val v-val)))
      (t
       (multiple-value-setq (px py pz)
         (cl-occt:face-center face))))
    (unless (and px py pz)
      (error "make-frame-on-face: could not determine point on face"))
    ;; Compute normal (Z-axis)
    (cond
      ((and u v (not point))
       (multiple-value-setq (nz-x nz-y nz-z)
         (%face-normal-at-uv face u-val v-val)))
      (t
       (multiple-value-setq (nz-x nz-y nz-z)
         (cl-occt:face-normal-at-center face))))
    (unless nz-x
      (error "make-frame-on-face: could not compute face normal"))
    ;; Compute U-direction for X-axis
    (multiple-value-bind (ux uy uz)
        (if surface
            (%surface-u-tangent surface u-val v-val)
            (values 1.0d0 0.0d0 0.0d0))
      ;; Compute Y-axis = cross(Z, X) for right-handed
      (multiple-value-bind (yx yy yz) (%vec-cross nz-x nz-y nz-z ux uy uz)
        (multiple-value-bind (ynx yny ynz) (%vec-normalize yx yy yz)
          (make-instance 'frame
            :origin (%vec-list px py pz)
            :x-axis (%vec-list ux uy uz)
            :y-axis (%vec-list ynx yny ynz)
            :z-axis (%vec-list nz-x nz-y nz-z)))))))

(defun make-frame-on-plane (origin-x origin-y origin-z
                             normal-x normal-y normal-z
                             &key up-x up-y up-z)
  "Construct a coordinate frame from a point and normal direction.

   The frame origin is at (`origin-x`, `origin-y`, `origin-z`).
   Z-axis is the normalized (`normal-x`, `normal-y`, `normal-z`).
   X-axis is the cross product of Z and UP (default UP = `(0 0 1)`).
   Y-axis is the cross product of Z and X (right-handed).

   - **origin-x** X coordinate of the frame origin (double-float)
   - **origin-y** Y coordinate of the frame origin (double-float)
   - **origin-z** Z coordinate of the frame origin (double-float)
   - **normal-x** X component of the normal direction (double-float)
   - **normal-y** Y component of the normal direction (double-float)
   - **normal-z** Z component of the normal direction (double-float)
   - **up-x** optional X component of the up direction (double-float, default `nil`)
   - **up-y** optional Y component of the up direction (double-float, default `nil`)
   - **up-z** optional Z component of the up direction (double-float, default `nil`)

   **Returns:** a `frame` instance.

   **Example:**

       ;; Frame on the XY plane
       (make-frame-on-plane 0 0 0 0 0 1)

       ;; Frame with custom up direction
       (make-frame-on-plane 0 0 0 1 0 0 :up-x 0 :up-y 0 :up-z 1)

   **See also:** `make-frame-on-face`, `frame-to-location`"
  (let* ((nx (float normal-x 1.0d0))
         (ny (float normal-y 1.0d0))
         (nz (float normal-z 1.0d0)))
    ;; Default up: if normal is near (0,0,±1) use (0,1,0), else use (0,0,1)
    ;; Use multiple-value-bind to capture all values from the VALUES form
    (multiple-value-bind (dux duy duz)
        (if (> (abs nz) 0.9d0)
            (values 0.0d0 1.0d0 0.0d0)
            (values 0.0d0 0.0d0 1.0d0))
      (let* ((ux (if up-x (float up-x 1.0d0) dux))
             (uy (if up-y (float up-y 1.0d0) duy))
             (uz (if up-z (float up-z 1.0d0) duz)))
        ;; Normalize inputs
        (multiple-value-bind (zx zy zz) (%vec-normalize nx ny nz)
          (multiple-value-bind (upx upy upz) (%vec-normalize ux uy uz)
            (multiple-value-bind (xxv xyv xzv) (%vec-cross zx zy zz upx upy upz)
              (let ((x-len (%vec-len xxv xyv xzv)))
                (if (<= x-len 1.0d-12)
                    (if (> (abs zz) 0.9d0)
                        (progn
                          (setf xxv 1.0d0 xyv 0.0d0 xzv 0.0d0))
                        (progn
                          (multiple-value-setq (xxv xyv xzv)
                            (%vec-cross zx zy zz 0.0d0 0.0d0 1.0d0))
                          (multiple-value-setq (xxv xyv xzv)
                            (%vec-normalize xxv xyv xzv))))
                    (multiple-value-setq (xxv xyv xzv)
                      (%vec-normalize xxv xyv xzv)))
                (multiple-value-bind (yx yy yz) (%vec-cross zx zy zz xxv xyv xzv)
                  (make-instance 'frame
                    :origin (%vec-list (float origin-x 1.0d0)
                                       (float origin-y 1.0d0)
                                       (float origin-z 1.0d0))
                    :x-axis (%vec-list xxv xyv xzv)
                    :y-axis (%vec-list yx yy yz)
                    :z-axis (%vec-list zx zy zz)))))))))))

(defun frame-to-location (frame)
  "Convert a coordinate frame to an OCCT location for use with `move-shape`.

   Produces a translation-only location from the frame's origin. The
   resulting location positions shapes at the frame's position.

   - **frame** a `frame` instance

   **Returns:** an OCCT location handle, or nil if the frame is invalid.

   **Example:**

       (let* ((box (make-box 10 20 30))
              (top (top-face box))
              (f (make-frame-on-face top))
              (loc (frame-to-location f)))
         (move-shape (make-sphere 5) loc))

   **See also:** `make-frame-on-face`, `make-frame-on-plane`, `move-shape`"
  (destructuring-bind (ox oy oz) (frame-origin frame)
    (cl-occt:make-location ox oy oz)))
