(in-package :clotcad)

(defvar *sketch-frame* nil
  "Dynamically bound during `sketch-on-face` evaluation.
   Provides the face coordinate frame for vertex reference resolution.")

(defstruct (sketch-point (:constructor %make-sketch-point))
  "A 2D point in a sketch's local coordinate system.

   - **x** X coordinate (double-float)
   - **y** Y coordinate (double-float)

   **Returns:** a `sketch-point` instance.

   **Example:**

       (pnt 3.5 7.0)

   **See also:** `sketch-on-face`, `rect`, `circle`, `slot`, `polygon`, `line-chain`"
  (x 0.0d0 :type double-float)
  (y 0.0d0 :type double-float))

(defun pnt (x y)
  "Create a 2D point for use within sketch primitives.

   - **x** X coordinate (real, coerced to double-float)
   - **y** Y coordinate (real, coerced to double-float)

   **Returns:** a `sketch-point` instance.

   **Example:**

       (pnt 3.5 7.0)
       (pnt 10 20)

   **See also:** `sketch-on-face`, `rect`, `circle`, `slot`, `polygon`, `line-chain`"
  (%make-sketch-point :x (float x 1.0d0) :y (float y 1.0d0)))

;; ─── Internal helpers ───

(defun %project-vertex-to-sketch (vertex-designator frame)
  (let* ((vertex (resolve-shape vertex-designator))
         (ox (first (frame-origin frame)))
         (oy (second (frame-origin frame)))
         (oz (third (frame-origin frame)))
         (xx (first (frame-x-axis frame)))
         (xy (second (frame-x-axis frame)))
         (xz (third (frame-x-axis frame)))
         (yx (first (frame-y-axis frame)))
         (yy (second (frame-y-axis frame)))
         (yz (third (frame-y-axis frame))))
    (multiple-value-bind (vx vy vz) (cl-occt:vertex-point vertex)
      (let ((dx (- vx ox))
            (dy (- vy oy))
            (dz (- vz oz)))
        (values (+ (* dx xx) (* dy xy) (* dz xz))
                (+ (* dx yx) (* dy yy) (* dz yz)))))))

(defun %resolve-sketch-point (point-designator)
  (etypecase point-designator
    (sketch-point
     (values (sketch-point-x point-designator)
             (sketch-point-y point-designator)))
    (t
     (unless *sketch-frame*
       (error "Vertex references require a sketch frame. Use inside sketch-on-face."))
     (%project-vertex-to-sketch point-designator *sketch-frame*))))

(defun %assemble-sketch-result (wires result-type frame)
  (let ((ox (first (frame-origin frame)))
        (oy (second (frame-origin frame)))
        (oz (third (frame-origin frame)))
        (nx (first (frame-z-axis frame)))
        (ny (second (frame-z-axis frame)))
        (nz (third (frame-z-axis frame))))
    (case result-type
      (:wire
       (if (null wires)
           (error "sketch-on-face: no primitives provided for :result-type :wire")
           (let* ((face (cl-occt:make-face-on-plane (first wires) ox oy oz nx ny nz))
                  (f-wires (cl-occt:face-wires face)))
             (if f-wires
                 (first f-wires)
                 (first wires)))))
      (:faces
       (if (null wires)
           (error "sketch-on-face: no primitives provided for :result-type :faces")
           (loop for w in wires
                 collect (cl-occt:make-face-on-plane w ox oy oz nx ny nz))))
      (t
       (if (null wires)
           (error "sketch-on-face: no primitives provided")
           (let ((result (cl-occt:make-face-on-plane (first wires) ox oy oz nx ny nz)))
             (dolist (w (rest wires))
               (let ((hole-face (cl-occt:make-face-on-plane w ox oy oz nx ny nz)))
                 (setf result (cl-occt:cut result hole-face))))
             result))))))

;; ─── Sketch primitives ───

(defun rect (corner width height)
  "Create a rectangular wire in the sketch plane.

   - **corner** a `sketch-point` or vertex designator for the bottom-left corner
   - **width** rectangle width (double-float)
   - **height** rectangle height (double-float)

   **Returns:** a closed wire shape forming a rectangle.

   **Example:**

       (rect (pnt 0 0) 10 20)

   **See also:** `sketch-on-face`, `circle`, `slot`, `polygon`, `line-chain`"
  (multiple-value-bind (x y) (%resolve-sketch-point corner)
    (let ((x2 (coerce (+ x (float width 1.0d0)) 'double-float))
          (y2 (coerce (+ y (float height 1.0d0)) 'double-float)))
      (cl-occt:make-wire
       (cl-occt:make-edge x y x2 y)
       (cl-occt:make-edge x2 y x2 y2)
       (cl-occt:make-edge x2 y2 x y2)
       (cl-occt:make-edge x y2 x y)))))

(defun circle (center radius)
  "Create a circular wire in the sketch plane.

   - **center** a `sketch-point` or vertex designator for the circle center
   - **radius** circle radius (double-float)

   **Returns:** a closed wire shape forming a circle.

   **Example:**

       (circle (pnt 0 0) 5)

   **See also:** `sketch-on-face`, `rect`, `slot`, `polygon`, `line-chain`"
  (multiple-value-bind (x y) (%resolve-sketch-point center)
    (cl-occt:make-wire (cl-occt:make-circle-edge x y (float radius 1.0d0)))))

(defun slot (center width height radius)
  "Create a slot-shaped wire (rectangle with rounded corners).

   - **center** a `sketch-point` or vertex designator for the slot center
   - **width** total slot width along X (double-float)
   - **height** total slot height along Y (double-float)
   - **radius** corner radius (double-float, clamped to half the minimum dimension)

   **Returns:** a closed wire shape forming a slot.

   **Example:**

       (slot (pnt 0 0) 12 6 2)

   **See also:** `sketch-on-face`, `rect`, `circle`, `polygon`, `line-chain`"
  (let ((cos45 (coerce (sqrt 0.5d0) 'double-float)))
    (multiple-value-bind (cx cy) (%resolve-sketch-point center)
      (let ((hw (* 0.5d0 (float width 1.0d0)))
            (hh (* 0.5d0 (float height 1.0d0)))
            (r (float radius 1.0d0)))
        (let ((left (- cx hw))
              (right (+ cx hw))
              (bottom (- cy hh))
              (top (+ cy hh))
               (r (min r hw hh)))
          (cl-occt:make-wire
           (cl-occt:make-circular-arc left (- top r)
                                      (+ left (* r (- 1.0d0 cos45))) (- top (* r (- 1.0d0 cos45)))
                                      (+ left r) top)
           (cl-occt:make-edge (+ left r) top (- right r) top)
           (cl-occt:make-circular-arc (- right r) top
                                      (- right (* r (- 1.0d0 cos45))) (- top (* r (- 1.0d0 cos45)))
                                      right (- top r))
           (cl-occt:make-edge right (- top r) right (+ bottom r))
           (cl-occt:make-circular-arc right (+ bottom r)
                                      (- right (* r (- 1.0d0 cos45))) (+ bottom (* r (- 1.0d0 cos45)))
                                      (- right r) bottom)
           (cl-occt:make-edge (- right r) bottom (+ left r) bottom)
           (cl-occt:make-circular-arc (+ left r) bottom
                                      (+ left (* r (- 1.0d0 cos45))) (+ bottom (* r (- 1.0d0 cos45)))
                                      left (+ bottom r))
           (cl-occt:make-edge left (+ bottom r) left (- top r))))))))

(defun polygon (&rest points)
  "Create a closed polygonal wire in the sketch plane.

   Accepts 3 or more points (each a `sketch-point` or vertex designator).
   The polygon is automatically closed back to the first point.

   - **points** `&rest` of `sketch-point` instances or vertex designators

   **Returns:** a closed wire shape forming a polygon.

   **Example:**

       (polygon (pnt 0 0) (pnt 5 0) (pnt 2.5 5))

   **See also:** `sketch-on-face`, `rect`, `circle`, `slot`, `line-chain`"
  (let ((resolved (loop for p in points
                        collect (multiple-value-list (%resolve-sketch-point p)))))
    (when (< (length resolved) 3)
      (error "polygon requires at least 3 points, got ~D" (length resolved)))
    (let ((n (length resolved))
          (edges nil))
      (loop for i from 0 below n
            for (x1 y1) = (nth i resolved)
            for (x2 y2) = (nth (mod (1+ i) n) resolved)
            do (push (cl-occt:make-edge x1 y1 x2 y2) edges))
      (apply #'cl-occt:make-wire (nreverse edges)))))

(defun line-chain (&rest args)
  "Create an open or closed chain of line edges in the sketch plane.

   Accepts 2 or more points (each a `sketch-point` or vertex designator).
   When `:closed t` is passed, the chain is closed back to the first point.

   - **args** `&rest` of `sketch-point` instances or vertex designators,
     followed by `&key closed` (default nil)

   **Returns:** a wire shape (open or closed).

   **Example:**

       (line-chain (pnt 0 0) (pnt 5 0) (pnt 5 5))
       (line-chain (pnt 0 0) (pnt 5 0) (pnt 5 5) :closed t)

   **See also:** `sketch-on-face`, `rect`, `circle`, `slot`, `polygon`"
  (let* ((closed-pos (position :closed args :test #'eq))
         (closed (if closed-pos (nth (1+ closed-pos) args) nil))
         (point-args (if closed-pos (subseq args 0 closed-pos) args)))
    (let ((resolved (loop for p in point-args
                          collect (multiple-value-list (%resolve-sketch-point p)))))
      (when (< (length resolved) 2)
        (error "line-chain requires at least 2 points, got ~D" (length resolved)))
      (let ((n (length resolved))
            (edges nil))
        (loop for i from 0 below (if closed n (1- n))
              for (x1 y1) = (nth i resolved)
              for (x2 y2) = (nth (mod (1+ i) n) resolved)
              do (push (cl-occt:make-edge x1 y1 x2 y2) edges))
        (apply #'cl-occt:make-wire (nreverse edges))))))

;; ─── Entry point ───

(defmacro sketch-on-face (face-designator &body args)
  "Evaluate sketch primitives on a face's coordinate frame.

   Resolves the face, creates a coordinate frame from its geometry,
   and evaluates each sketch primitive (rect, circle, slot, polygon,
   line-chain) in that frame. Primitives use local 2D coordinates
   via `pnt` or vertex designators that are projected onto the
   sketch plane.

   - **face-designator** a face shape, symbol, or compound symbol (:model/face)
   - **args** `&body` containing sketch primitives, optionally followed by
     `:result-type :face` | `:faces` | `:wire` (default `:face`)

   **Returns:** depends on `:result-type`:
   - `:face` (default) — a single face (compound face with holes for
     multiple primitives when the first wire encloses the others)
   - `:faces` — a list of separate face objects, one per primitive
   - `:wire` — a single wire shape (outer wire of the first primitive)

   **Example:**

       ;; Simple rectangle on a face
       (sketch-on-face :my-box/top-face (rect (pnt 2 2) 6 6))

       ;; Rectangle with a circular hole
       (sketch-on-face :my-box/top-face
         (rect (pnt 2 2) 8 8) (circle (pnt 6 6) 2))

       ;; Multiple separate faces
       (sketch-on-face :my-box/top-face
         (rect (pnt 2 2) 6 6) (circle (pnt 5 5) 1)
         :result-type :faces)

       ;; Extract wire
       (sketch-on-face :my-box/top-face
         (rect (pnt 2 2) 6 6)
         :result-type :wire)

       ;; Vertex references
       (sketch-on-face :box/top-face
         (rect :box/edge-start 10 10))

   **See also:** `pnt`, `rect`, `circle`, `slot`, `polygon`, `line-chain`,
   `extrude-from-face`"
  (let ((result-type :face)
        (primitives args))
    (let ((pos (position :result-type args)))
      (when pos
        (setf result-type (nth (1+ pos) args)
              primitives (append (subseq args 0 pos) (subseq args (+ pos 2))))))
    `(let* ((face (resolve-shape ,face-designator))
            (frame (make-frame-on-face face))
            (*sketch-frame* frame))
       (let ((wires (list ,@primitives)))
         (%assemble-sketch-result wires ,result-type frame)))))

;; ─── Convenience ───

(defun extrude-from-face (face-designator sketch &key (depth 10.0d0) direction)
  "Convenience: sketch-on-face + prism + boolean cut.

   Sketches on the given face, extrudes the result along the face
   normal (or a custom direction) into the body, and performs a
   boolean cut on the parent shape.

   - **face-designator** a compound symbol like `:box/top-face` identifying
     the face to sketch on (must be resolvable to a parent model)
   - **sketch** the result of a `sketch-on-face` call (a face, list of faces,
     or wire)
   - **depth** extrusion depth (double-float, default 10.0)
   - **direction** optional list `(dx dy dz)` to override the face normal
     direction. When omitted, extrudes opposite to the face outward
     normal (into the body).

   **Returns:** a new shape — the parent body with the extruded profile
   cut out.

   **Example:**

       (extrude-from-face :box/top-face
         (sketch-on-face :box/top-face (circle (pnt 5 5) 2)))

   **See also:** `sketch-on-face`, `make-prism`"
  (let* ((face (resolve-shape face-designator))
         (frame (make-frame-on-face face))
         (nx (first (frame-z-axis frame)))
         (ny (second (frame-z-axis frame)))
         (nz (third (frame-z-axis frame))))
    (multiple-value-bind (dx dy dz)
        (if direction
            (values (* (first direction) depth)
                    (* (second direction) depth)
                    (* (third direction) depth))
            (values (* (- nx) depth)
                    (* (- ny) depth)
                    (* (- nz) depth)))
      (let* ((extruded (cl-occt:make-prism sketch dx dy dz))
             (parent-model (%parse-compound-symbol face-designator)))
        (if parent-model
            (let ((parent (resolve-shape parent-model)))
              (cl-occt:cut parent extruded))
            (error "extrude-from-face: cannot determine parent body from ~S. \
Use a compound symbol like :box/top-face."
                   face-designator))))))
