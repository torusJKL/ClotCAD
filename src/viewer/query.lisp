(in-package :clotcad)

;; ─── Internal helpers ───

(defun %subshape-center (shape)
  "Return the 3D center of a subshape as three values (cx, cy, cz)."
  (case (cl-occt:shape-type shape)
    (:face
     (cl-occt:face-center shape))
    (:edge
     (multiple-value-bind (curve first last) (cl-occt:edge-curve-range shape)
       (when curve
         (cl-occt:curve-value curve (/ (+ first last) 2.0d0)))))
    (:vertex
     (cl-occt:vertex-point shape))
    (t
     (values 0.0d0 0.0d0 0.0d0))))

(defun %edge-direction (edge)
  "Return the unit tangent direction of an edge as three values (dx, dy, dz)."
  (multiple-value-bind (curve first last) (cl-occt:edge-curve-range edge)
    (when curve
      (cl-occt:curve-tangent-at curve (/ (+ first last) 2.0d0)))))

(defun %edge-radius (edge)
  "Return the radius of a circular edge as two values (radius, ok)."
  (unless (eq (cl-occt:edge-curve-type edge) :circle)
    (return-from %edge-radius (values nil nil)))
  (let ((curve (cl-occt:edge-curve edge)))
    (unless curve
      (return-from %edge-radius (values nil nil)))
    (let ((k (cl-occt:curve-curvature-at curve 0.0d0)))
      (if (and k (> k 0.0d0))
          (values (/ 1.0d0 k) t)
          (values nil nil)))))

(defun %normalize (dx dy dz)
  "Normalize a 3-vector, returning three values."
  (let ((len (sqrt (+ (* dx dx) (* dy dy) (* dz dz)))))
    (if (> len 0.0d0)
        (values (/ dx len) (/ dy len) (/ dz len))
        (values 0.0d0 0.0d0 0.0d0))))

(defun %cos-angle (deg)
  (cos (* (float deg 1.0d0) (/ pi 180.0d0))))

;; ─── Predicate functions (each returns a list-filtering closure) ───

(defun face-p ()
  "Return a predicate closure that keeps only face subshapes.

   **Returns:** a function accepting a list of shapes and returning a filtered list.

   **Example:**

       (query-shape :my-box :where (list (face-p) (normal-along 0 0 1)))

   **See also:** `edge-p`, `vertex-p`"
  (lambda (shapes)
    (remove-if-not (lambda (s) (eq (cl-occt:shape-type s) :face)) shapes)))

(defun edge-p ()
  "Return a predicate closure that keeps only edge subshapes."
  (lambda (shapes)
    (remove-if-not (lambda (s) (eq (cl-occt:shape-type s) :edge)) shapes)))

(defun vertex-p ()
  "Return a predicate closure that keeps only vertex subshapes."
  (lambda (shapes)
    (remove-if-not (lambda (s) (eq (cl-occt:shape-type s) :vertex)) shapes)))

(defun normal-along (dx dy dz &key (angle-deg 1.0) (coordinate-system :local))
  "Return a predicate closure that filters faces by normal direction.

   - **dx**, **dy**, **dz** direction vector components
   - **angle-deg** tolerance in degrees (default 1.0)
   - **coordinate-system** `:local` or `:global` (default `:local`)

   **Returns:** a function accepting a list of shapes and returning a filtered list.

   **Example:**

       (query-shape :my-box :where (list (face-p) (normal-along 0 0 1)))

   **See also:** `edge-along`"
  (declare (ignore coordinate-system))
  (let* ((limit (%cos-angle angle-deg))
         (vx 0.0d0) (vy 0.0d0) (vz 0.0d0))
    (multiple-value-setq (vx vy vz) (%normalize (float dx) (float dy) (float dz)))
    (lambda (shapes)
      (remove-if-not
       (lambda (s)
         (multiple-value-bind (nx ny nz) (cl-occt:face-normal-at-center s)
           (and nx (>= (+ (* nx vx) (* ny vy) (* nz vz)) limit))))
       shapes))))

(defun surface-type (surface-keyword)
  "Return a predicate closure that filters faces by surface type.

   - **surface-keyword** one of `:plane`, `:cylinder`, `:cone`, `:sphere`, `:torus`

   **Returns:** a function accepting a list of shapes and returning a filtered list.

   **Example:**

       (query-shape :my-box :where (list (face-p) (surface-type :plane)))

   **See also:** `curve-type`"
  (lambda (shapes)
    (remove-if-not
     (lambda (s) (eq (cl-occt:face-surface-type s) surface-keyword))
     shapes)))

(defun curve-type (curve-keyword)
  "Return a predicate closure that filters edges by curve type.

   - **curve-keyword** one of `:line`, `:circle`, `:ellipse`, `:hyperbola`, `:parabola`

   **Returns:** a function accepting a list of shapes and returning a filtered list.

   **Example:**

       (query-shape :my-cylinder :where (list (edge-p) (curve-type :circle)))

   **See also:** `surface-type`"
  (lambda (shapes)
    (remove-if-not
     (lambda (s) (eq (cl-occt:edge-curve-type s) curve-keyword))
     shapes)))

(defun longer-than (threshold)
  "Return a predicate closure that filters edges longer than a threshold.

   - **threshold** length in mm

   **Returns:** a function accepting a list of shapes and returning a filtered list.

   **See also:** `shorter-than`"
  (let ((limit (float threshold)))
    (lambda (shapes)
      (remove-if-not
       (lambda (s)
         (let ((len (cl-occt:edge-length s)))
           (and len (> len limit))))
       shapes))))

(defun shorter-than (threshold)
  "Return a predicate closure that filters edges shorter than a threshold.

   - **threshold** length in mm

   **Returns:** a function accepting a list of shapes and returning a filtered list.

   **See also:** `longer-than`"
  (let ((limit (float threshold)))
    (lambda (shapes)
      (remove-if-not
       (lambda (s)
         (let ((len (cl-occt:edge-length s)))
           (and len (< len limit))))
       shapes))))

(defun larger-than (threshold)
  "Return a predicate closure that filters faces larger than a threshold.

   - **threshold** area in mm²

   **Returns:** a function accepting a list of shapes and returning a filtered list.

   **See also:** `smaller-than`"
  (let ((limit (float threshold)))
    (lambda (shapes)
      (remove-if-not
       (lambda (s)
         (let ((area (cl-occt:face-area s)))
           (and area (> area limit))))
       shapes))))

(defun smaller-than (threshold)
  "Return a predicate closure that filters faces smaller than a threshold.

   - **threshold** area in mm²

   **Returns:** a function accepting a list of shapes and returning a filtered list.

   **See also:** `larger-than`"
  (let ((limit (float threshold)))
    (lambda (shapes)
      (remove-if-not
       (lambda (s)
         (let ((area (cl-occt:face-area s)))
           (and area (< area limit))))
       shapes))))

(defun max-by (fn)
  "Return a predicate closure that selects the subshape with maximum (FN subshape).

   - **fn** a function of one argument (a shape) returning a numeric value

   **Returns:** a function accepting a list of shapes and returning a list of one element.

   **Example:**

       (query-shape :my-box :where (list (face-p) (max-by #'cl-occt:face-area)))

   **See also:** `min-by`"
  (lambda (shapes)
    (if shapes
        (list (reduce (lambda (a b)
                        (if (> (funcall fn a) (funcall fn b)) a b))
                      shapes))
        '())))

(defun min-by (fn)
  "Return a predicate closure that selects the subshape with minimum (FN subshape).

   - **fn** a function of one argument (a shape) returning a numeric value

   **Returns:** a function accepting a list of shapes and returning a list of one element.

   **Example:**

       (query-shape :my-box :where (list (edge-p) (min-by #'cl-occt:edge-length)))

   **See also:** `max-by`"
  (lambda (shapes)
    (if shapes
        (list (reduce (lambda (a b)
                        (if (< (funcall fn a) (funcall fn b)) a b))
                      shapes))
        '())))

(defun x-center (value &key (tolerance 1.0d-6))
  "Return a predicate closure that filters subshapes by center X coordinate.

   - **value** target X coordinate
   - **tolerance** acceptable deviation (default 1e-6)

   **Returns:** a function accepting a list of shapes and returning a filtered list.

   **See also:** `y-center`, `z-center`"
  (let ((target (float value))
        (tol (float tolerance)))
    (lambda (shapes)
      (remove-if-not
       (lambda (s)
         (multiple-value-bind (cx cy cz) (%subshape-center s)
           (declare (ignore cy cz))
           (<= (abs (- cx target)) tol)))
       shapes))))

(defun y-center (value &key (tolerance 1.0d-6))
  "Return a predicate closure that filters subshapes by center Y coordinate.

   - **value** target Y coordinate
   - **tolerance** acceptable deviation (default 1e-6)

   **Returns:** a function accepting a list of shapes and returning a filtered list.

   **See also:** `x-center`, `z-center`"
  (let ((target (float value))
        (tol (float tolerance)))
    (lambda (shapes)
      (remove-if-not
       (lambda (s)
         (multiple-value-bind (cx cy cz) (%subshape-center s)
           (declare (ignore cx cz))
           (<= (abs (- cy target)) tol)))
       shapes))))

(defun z-center (value &key (tolerance 1.0d-6))
  "Return a predicate closure that filters subshapes by center Z coordinate.

   - **value** target Z coordinate
   - **tolerance** acceptable deviation (default 1e-6)

   **Returns:** a function accepting a list of shapes and returning a filtered list.

   **Example:**

       (query-shape :my-box :where (list (face-p) (z-center 15)))

   **See also:** `x-center`, `y-center`"
  (let ((target (float value))
        (tol (float tolerance)))
    (lambda (shapes)
      (remove-if-not
       (lambda (s)
         (multiple-value-bind (cx cy cz) (%subshape-center s)
           (declare (ignore cx cy))
           (<= (abs (- cz target)) tol)))
       shapes))))

(defun edge-along (dx dy dz &key (angle-deg 1.0) (coordinate-system :local))
  "Return a predicate closure that filters edges by direction alignment.

   - **dx**, **dy**, **dz** direction vector components
   - **angle-deg** tolerance in degrees (default 1.0)
   - **coordinate-system** `:local` or `:global` (default `:local`)

   **Returns:** a function accepting a list of shapes and returning a filtered list.

   **Example:**

       (query-shape :my-box :where (list (edge-p) (edge-along 0 0 1)))

   **See also:** `normal-along`"
  (declare (ignore coordinate-system))
  (let* ((limit (%cos-angle angle-deg))
         (vx 0.0d0) (vy 0.0d0) (vz 0.0d0))
    (multiple-value-setq (vx vy vz) (%normalize (float dx) (float dy) (float dz)))
    (lambda (shapes)
      (remove-if-not
       (lambda (s)
         (multiple-value-bind (ex ey ez) (%edge-direction s)
           (and ex (>= (abs (+ (* ex vx) (* ey vy) (* ez vz))) limit))))
       shapes))))

(defun radius-around (value &key (tolerance 1.0d-6) (coordinate-system :local))
  "Return a predicate closure that filters circular edges by radius.

   - **value** target radius
   - **tolerance** acceptable deviation (default 1e-6)
   - **coordinate-system** `:local` or `:global` (default `:local`)

   **Returns:** a function accepting a list of shapes and returning a filtered list.

   **Example:**

       (query-shape (make-cylinder 5 20) :where (list (edge-p) (radius-around 5)))

   **See also:** `curve-type`"
  (declare (ignore coordinate-system))
  (let ((target (float value))
        (tol (float tolerance)))
    (lambda (shapes)
      (remove-if-not
       (lambda (s)
         (multiple-value-bind (r ok) (%edge-radius s)
           (and ok (<= (abs (- r target)) tol))))
       shapes))))

;; ─── Public query entry point ───

(defun query-shape (designator &key (where nil) (coordinate-system :local))
  "Query subshapes of a 3D shape by a pipeline of predicate closures.

   Resolves DESIGNATOR via `resolve-shape`, collects all faces, edges,
   and vertices, then applies each predicate in WHERE left-to-right.

   - **designator** a shape, symbol, or string
   - **where** a list of predicate closures (returned by `face-p`, `normal-along`, etc.)

   **Returns:** a list of subshapes matching all predicates.

   **Example:**

       (query-shape (make-box 10 20 30)
                    :where (list (face-p) (normal-along 0 0 1) (max-by #'cl-occt:face-area)))

   **See also:** `top-face`, `bottom-face`, `longest-edge`, `largest-face`"
  (declare (ignore coordinate-system))
  (let* ((shape (resolve-shape designator))
         (subshapes (append (cl-occt:map-shape-subshapes shape :face)
                            (cl-occt:map-shape-subshapes shape :edge)
                            (cl-occt:map-shape-subshapes shape :vertex))))
    (dolist (pred where subshapes)
      (setf subshapes (funcall pred subshapes)))))

;; ─── Convenience accessors ───

(defun top-face (designator)
  "Return the top-most planar face of a shape.

   Finds the planar face with the highest Z-center whose outward normal
   is aligned with +Z.

   - **designator** a shape, symbol, or string

   **Returns:** a single face shape, or nil.

   **Example:**

       (top-face (make-box 10 20 30))

   **See also:** `bottom-face`, `query-shape`"
  (first (query-shape designator
                      :where (list (face-p) (surface-type :plane)
                                   (normal-along 0 0 1)
                                   (max-by #'cl-occt:face-center)))))

(defun bottom-face (designator)
  "Return the bottom-most planar face of a shape.

   Finds the planar face with the lowest Z-center whose outward normal
   is aligned with -Z.

   - **designator** a shape, symbol, or string

   **Returns:** a single face shape, or nil.

   **Example:**

       (bottom-face (make-box 10 20 30))

   **See also:** `top-face`, `query-shape`"
  (first (query-shape designator
                      :where (list (face-p) (surface-type :plane)
                                   (normal-along 0 0 -1)
                                   (min-by #'cl-occt:face-center)))))

(defun longest-edge (designator)
  "Return the longest edge of a shape.

   - **designator** a shape, symbol, or string

   **Returns:** a single edge shape, or nil.

   **Example:**

       (longest-edge (make-box 10 20 30))

   **See also:** `shortest-edge`, `query-shape`"
  (first (query-shape designator
                      :where (list (edge-p)
                                   (max-by #'cl-occt:edge-length)))))

(defun shortest-edge (designator)
  "Return the shortest edge of a shape.

   - **designator** a shape, symbol, or string

   **Returns:** a single edge shape, or nil.

   **Example:**

       (shortest-edge (make-box 10 20 30))

   **See also:** `longest-edge`, `query-shape`"
  (first (query-shape designator
                      :where (list (edge-p)
                                   (min-by #'cl-occt:edge-length)))))

(defun largest-face (designator)
  "Return the largest face of a shape by area.

   - **designator** a shape, symbol, or string

   **Returns:** a single face shape, or nil.

   **Example:**

       (largest-face (make-box 10 20 30))

   **See also:** `smallest-face`, `query-shape`"
  (first (query-shape designator
                      :where (list (face-p)
                                   (max-by #'cl-occt:face-area)))))

(defun smallest-face (designator)
  "Return the smallest face of a shape by area.

   - **designator** a shape, symbol, or string

   **Returns:** a single face shape, or nil.

   **Example:**

       (smallest-face (make-box 10 20 30))

   **See also:** `largest-face`, `query-shape`"
  (first (query-shape designator
                      :where (list (face-p)
                                   (min-by #'cl-occt:face-area)))))
