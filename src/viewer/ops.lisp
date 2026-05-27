(in-package :clotcad)

(defvar *show-defs-in-tree* t
  "When non-nil, def-ined shapes appear in the Scene Tree.
   When nil, they are hidden from the tree but can still be operated on.")

(defun %set-subshape-visible (model-name subshape-name visible)
  (let* ((sname (string model-name))
         (m (clotcad.impl:find-model sname)))
    (unless m
      (error "~S does not name a known model" model-name))
    (let* ((key (intern (string-upcase (string subshape-name)) :keyword))
           (entry (assoc key (clotcad.impl:model-named-subshapes m) :test #'eq)))
      (unless entry
        (error "Named subshape ~S not found on ~S" subshape-name model-name))
      (setf (getf (cdr entry) :visible) visible)
      (queue-push :sync))))

(defmacro def (name shape-form)
  "Define a named shape without displaying it.

  The shape is stored in the DAG registry and the scene tree
  (grayed). Use `show` to make it visible in the 3D view.

  - **name** keyword or string naming the shape
  - **shape-form** form that evaluates to a `shape` object

  **Returns:** the shape value.

  **Example:**

      (def :my-box (make-box 10 20 30))
      (show :my-box)

  **See also:** `show`, `hide`, `toggle`"
  `(let* ((shape ,shape-form)
          (sname (string ',name)))
     (register-model sname (make-model :name sname
                                       :cached-shape shape))
     (display ',name shape
              :visible nil
              :show-in-tree *show-defs-in-tree*
              :origin :def)
     shape))

(defun show (&rest names)
  "Show one or more named shapes in the 3D view.

  Shapes must have been previously defined with `display` or `def`.

  - **names** `&rest` of keywords or strings identifying shapes to show

  **Example:**

      (def :box (make-box 10 20 30))
      (show :box)

  To show a named subshape (child of a model), use the compound symbol
  syntax `model/subshape`:

      (name-subshape :my-box :top-face
        :where (list (face-p) (normal-along 0 0 1)))
      (show :my-box/top-face)

  **See also:** `hide`, `toggle`, `def`, `name-subshape`"
  (dolist (name names)
    (multiple-value-bind (model-name subshape-name)
        (and (symbolp name) (%parse-compound-symbol name))
      (if model-name
          (%set-subshape-visible model-name subshape-name t)
          (let* ((sname (string name))
                 (entry (gethash sname *displayed-models*)))
            (if entry
                (progn
                  (setf (second entry) t)
                  (queue-push :sync))
                ;; Not yet displayed — resolve from registry and display
                (let ((m (find-model sname)))
                  (if m
                      (let ((shape (model-cached-shape m)))
                        (when shape
                          (display name shape :visible t :show-in-tree t :origin :def)))
                      (error "~S does not name a known shape" name)))))))))

(defun hide (&rest names)
  "Hide one or more named shapes from the 3D view.

  Shapes remain in the scene tree and can be shown again with `show`.

  - **names** `&rest` of keywords or strings identifying shapes to hide

  **Example:**

      (hide :box)
      (hide :box :sphere)

  To hide a named subshape, use the compound symbol syntax:

      (hide :my-box/top-face)

  **See also:** `show`, `toggle`"
  (dolist (name names)
    (multiple-value-bind (model-name subshape-name)
        (and (symbolp name) (%parse-compound-symbol name))
      (if model-name
          (%set-subshape-visible model-name subshape-name nil)
          (let* ((sname (string name))
                 (entry (gethash sname *displayed-models*)))
            (if entry
                (progn
                  (setf (second entry) nil)
                  (queue-push :sync))
                (error "~S is not currently displayed" name)))))))

(defun toggle (&rest names)
  "Toggle visibility of one or more named shapes.

  Visible shapes become hidden, hidden shapes become visible.

  - **names** `&rest` of keywords or strings identifying shapes to toggle

  **Example:**

      (toggle :box)
      (toggle :box :sphere)

  To toggle a named subshape, use the compound symbol syntax:

      (toggle :my-box/top-face)

  **See also:** `show`, `hide`"
  (dolist (name names)
    (multiple-value-bind (model-name subshape-name)
        (and (symbolp name) (%parse-compound-symbol name))
      (if model-name
          (let* ((sname (string model-name))
                 (m (clotcad.impl:find-model sname))
                 (key (intern (string-upcase (string subshape-name)) :keyword))
                 (entry (assoc key (clotcad.impl:model-named-subshapes m) :test #'eq)))
            (unless entry
              (error "Named subshape ~S not found on ~S" subshape-name model-name))
            (%set-subshape-visible model-name subshape-name
                                   (not (getf (cdr entry) :visible))))
          (let* ((sname (string name))
                 (entry (gethash sname *displayed-models*)))
            (if entry
                (progn
                  (setf (second entry) (not (second entry)))
                  (queue-push :sync))
                (error "~S is not currently displayed" name)))))))

(defun show-defs (on)
  "Show or hide all def-ined shapes in the Scene Tree.

  When NIL, shapes created with `def` are hidden from the tree
  but can still be operated on by name.

  - **on** boolean, `t` to show def shapes in tree, `nil` to hide them

  **Example:**

      (show-defs nil)   ;; hide def shapes from tree
      (show-defs t)     ;; show them again

  **See also:** `toggle-defs`, `def`"
  (setf *show-defs-in-tree* on)
  (maphash (lambda (name entry)
             (when (eq (fifth entry) :def)
               (setf (third entry) on)))
           *displayed-models*)
  (queue-push :sync))

(defun toggle-defs ()
  "Toggle visibility of def-ined shapes in the Scene Tree.

  **Example:**

      (toggle-defs)

  **See also:** `show-defs`"
  (show-defs (not *show-defs-in-tree*)))

;; --- Wrapper functions ---

(defun cut (shape &rest others)
  "Perform a boolean cut (subtraction) operation.

  Subtracts OTHERS from SHAPE. Designators may be symbols,
  strings, or raw shapes.

  - **shape** the base shape (designator)
  - **others** `&rest` shapes to subtract (designators)

  **Returns:** a new `shape` representing `shape` minus the volume of all `others`.

  **Example:**

      (display :result (cut (make-box 10 10 10)
                            (make-sphere 5)))
      (def :a (make-box 10 20 30))
      (def :b (make-sphere 15))
      (cut :a :b)

  **See also:** `fuse`, `common`, `section`"
  (apply #'cl-occt:cut (resolve-shape shape) (mapcar #'resolve-shape others)))

(defun fuse (shape &rest others)
  "Perform a boolean fuse (union) operation.

  Merges OTHERS into SHAPE. Designators may be symbols,
  strings, or raw shapes.

  - **shape** the base shape (designator)
  - **others** `&rest` shapes to union (designators)

  **Returns:** a new `shape` representing the union of `shape` and all `others`.

  **Example:**

      (display :result (fuse (make-box 10 10 10)
                             (make-sphere 8)))

  **See also:** `cut`, `common`, `section`"
  (apply #'cl-occt:fuse (resolve-shape shape) (mapcar #'resolve-shape others)))

(defun common (shape &rest others)
  "Perform a boolean common (intersection) operation.

  Returns the volume shared by SHAPE and OTHERS. Designators
  may be symbols, strings, or raw shapes.

  - **shape** the first shape (designator)
  - **others** `&rest` shapes to intersect (designators)

  **Returns:** a new `shape` representing the intersection of `shape` and all `others`.

  **Example:**

      (display :result (common (make-box 10 10 10)
                               (make-sphere 8)))

  **See also:** `cut`, `fuse`, `section`"
  (apply #'cl-occt:common (resolve-shape shape) (mapcar #'resolve-shape others)))

(defun section (shape &rest others)
  "Perform a boolean section (intersection curves) operation.

  Returns the intersection curves between SHAPE and OTHERS,
  not a solid. Designators may be symbols, strings, or raw shapes.

  - **shape** the first shape (designator)
  - **others** `&rest` shapes to intersect (designators)

  **Returns:** a new shape containing the intersection curves.

  **Example:**

      (display :curves (section (make-box 10 10 10)
                                (make-sphere 8)))

  **See also:** `cut`, `fuse`, `common`"
  (apply #'cl-occt:section (resolve-shape shape) (mapcar #'resolve-shape others)))

(defun translate (shape dx dy dz)
  "Translate (move) a shape by a vector.

  Designator may be a symbol, string, or raw shape.

  - **shape** the shape to move (designator)
  - **dx** displacement along X axis (double-float)
  - **dy** displacement along Y axis (double-float)
  - **dz** displacement along Z axis (double-float)

  **Returns:** a new translated `shape`.

  **Example:**

      (display :moved (translate (make-box 10 10 10) 20 0 0))

  **See also:** `rotate`"
  (cl-occt:translate (resolve-shape shape) dx dy dz))

(defun rotate (shape ax ay az angle-deg)
  "Rotate a shape around an axis by an angle in degrees.

  The axis is defined by the vector (AX, AY, AZ). Designator
  may be a symbol, string, or raw shape.

  - **shape** the shape to rotate (designator)
  - **ax** X component of the rotation axis (double-float)
  - **ay** Y component of the rotation axis (double-float)
  - **az** Z component of the rotation axis (double-float)
  - **angle-deg** rotation angle in degrees (double-float)

  **Returns:** a new rotated `shape`.

  **Example:**

      (display :rotated (rotate (make-box 10 10 10) 0 0 1 45))

  **See also:** `translate`"
  (cl-occt:rotate (resolve-shape shape) ax ay az angle-deg))

(defun make-prism (shape dx dy dz)
  "Extrude (prism) a face or wire along a vector.

  Designator may be a symbol, string, or raw shape.

  - **shape** the face or wire to extrude (designator)
  - **dx** extrusion vector X component (double-float)
  - **dy** extrusion vector Y component (double-float)
  - **dz** extrusion vector Z component (double-float)

  **Returns:** a new extruded `shape`.

  **Example:**

      (def :wire (make-wire (make-edge 0 0 10 0)
                            (make-edge 10 0 10 10)
                            (make-edge 10 10 0 10)
                            (make-edge 0 10 0 0)))
      (display :face (make-face :wire))
      (display :prism (make-prism :face 0 0 20))

  **See also:** `make-revol`"
  (cl-occt:make-prism (resolve-shape shape) dx dy dz))

(defun make-revol (shape ax ay az angle-deg)
  "Revolve a shape around an axis by an angle in degrees.

  Designator may be a symbol, string, or raw shape.

  - **shape** the shape to revolve (designator)
  - **ax** revolution axis X component (double-float)
  - **ay** revolution axis Y component (double-float)
  - **az** revolution axis Z component (double-float)
  - **angle-deg** revolution angle in degrees (double-float)

  **Returns:** a new revolved `shape`.

  **Example:**

      (display :revol (make-revol (make-face-on-plane
                                   (make-wire (make-circle2d 0 0 10))
                                   0 0 0 0 0 1)
                                  0 0 1 180))

  **See also:** `make-prism`"
  (cl-occt:make-revol (resolve-shape shape) ax ay az angle-deg))

(defun make-compound (shapes)
  "Create a compound shape from a list of shapes.

  Each element of SHAPES may be a symbol, string, or raw shape.

  - **shapes** a list of shape designators to group

  **Returns:** a new compound `shape`.

  **Example:**

      (display :assy (make-compound (list (make-box 10 10 10)
                                          (make-sphere 8))))

  **See also:** `make-part`"
  (cl-occt:make-compound (mapcar #'resolve-shape shapes)))

(defun make-part (shape &key name color location)
  "Create a part (top-level shape with metadata).

  - **shape** the base shape (designator)
  - **name** optional string display name
  - **color** optional keyword or RGB triple for the part
  - **location** optional `gp_Trsf` transformation

  **Returns:** a new part `shape`.

  **Example:**

      (display :bolt (make-part (make-cylinder 5 20)
                                 :name \"M6 Bolt\"
                                 :color :cyan))

  **See also:** `make-compound`"
  (cl-occt:make-part (resolve-shape shape) :name name :color color :location location))

(defun write-step (shape filename)
  "Export a shape to STEP format.

  Designator may be a symbol, string, or raw shape.

  - **shape** the shape to export (designator)
  - **filename** path string for the output `.step` file

  **Example:**

      (write-step :result \"output.step\")

  **See also:** `write-stl`"
  (cl-occt:write-step (resolve-shape shape) filename))

(defun write-stl (shape filename &key (deflection 0.1d0))
  "Export a shape to STL format.

  Designator may be a symbol, string, or raw shape.

  - **shape** the shape to export (designator)
  - **filename** path string for the output `.stl` file
  - **deflection** optional mesh quality control, smaller = finer mesh (default `0.1d0`)

  **Example:**

      (write-stl :result \"output.stl\")
      (write-stl :result \"output.stl\" :deflection 0.01)

  **See also:** `write-step`"
  (cl-occt:write-stl (resolve-shape shape) filename :deflection deflection))
