(in-package :clotcad)

(defvar *show-defs-in-tree* t
  "When non-nil, def-ined shapes appear in the Scene Tree.
   When nil, they are hidden from the tree but can still be operated on.")

(defmacro def (name shape-form)
  "Define a named shape without displaying it.

  The shape is stored in the DAG registry and the scene tree
  (grayed). Use `show` to make it visible in the 3D view.

  Example:

      (def :my-box (make-box 10 20 30))
      (show :my-box)

  See also: `show`, `hide`, `toggle`"
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

  Example:

      (def :box (make-box 10 20 30))
      (show :box)

  See also: `hide`, `toggle`, `def`"
  (dolist (name names)
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
                (error "~S does not name a known shape" name)))))))

(defun hide (&rest names)
  "Hide one or more named shapes from the 3D view.

  Shapes remain in the scene tree and can be shown again with `show`.

  Example:

      (hide :box)
      (hide :box :sphere)

  See also: `show`, `toggle`"
  (dolist (name names)
    (let* ((sname (string name))
           (entry (gethash sname *displayed-models*)))
      (if entry
          (progn
            (setf (second entry) nil)
            (queue-push :sync))
          (error "~S is not currently displayed" name)))))

(defun toggle (&rest names)
  "Toggle visibility of one or more named shapes.

  Visible shapes become hidden, hidden shapes become visible.

  Example:

      (toggle :box)
      (toggle :box :sphere)

  See also: `show`, `hide`"
  (dolist (name names)
    (let* ((sname (string name))
           (entry (gethash sname *displayed-models*)))
      (if entry
          (progn
            (setf (second entry) (not (second entry)))
            (queue-push :sync))
          (error "~S is not currently displayed" name)))))

(defun show-defs (on)
  "Show or hide all def-ined shapes in the Scene Tree.

  When NIL, shapes created with `def` are hidden from the tree
  but can still be operated on by name.

  Example:

      (show-defs nil)   ;; hide def shapes from tree
      (show-defs t)     ;; show them again

  See also: `toggle-defs`, `def`"
  (setf *show-defs-in-tree* on)
  (maphash (lambda (name entry)
             (when (eq (fifth entry) :def)
               (setf (third entry) on)))
           *displayed-models*)
  (queue-push :sync))

(defun toggle-defs ()
  "Toggle visibility of def-ined shapes in the Scene Tree.

  Example:

      (toggle-defs)

  See also: `show-defs`"
  (show-defs (not *show-defs-in-tree*)))

;; --- Wrapper functions ---

(defun cut (shape &rest others)
  "Perform a boolean cut (subtraction) operation.

  Subtracts OTHERS from SHAPE. Designators may be symbols,
  strings, or raw shapes.

  Example:

      (display :result (cut (make-box 10 10 10)
                            (make-sphere 5)))
      (def :a (make-box 10 20 30))
      (def :b (make-sphere 15))
      (cut :a :b)

  See also: `fuse`, `common`, `section`"
  (apply #'cl-occt:cut (resolve-shape shape) (mapcar #'resolve-shape others)))

(defun fuse (shape &rest others)
  "Perform a boolean fuse (union) operation.

  Merges OTHERS into SHAPE. Designators may be symbols,
  strings, or raw shapes.

  Example:

      (display :result (fuse (make-box 10 10 10)
                             (make-sphere 8)))

  See also: `cut`, `common`, `section`"
  (apply #'cl-occt:fuse (resolve-shape shape) (mapcar #'resolve-shape others)))

(defun common (shape &rest others)
  "Perform a boolean common (intersection) operation.

  Returns the volume shared by SHAPE and OTHERS. Designators
  may be symbols, strings, or raw shapes.

  Example:

      (display :result (common (make-box 10 10 10)
                               (make-sphere 8)))

  See also: `cut`, `fuse`, `section`"
  (apply #'cl-occt:common (resolve-shape shape) (mapcar #'resolve-shape others)))

(defun section (shape &rest others)
  "Perform a boolean section (intersection curves) operation.

  Returns the intersection curves between SHAPE and OTHERS,
  not a solid. Designators may be symbols, strings, or raw shapes.

  Example:

      (display :curves (section (make-box 10 10 10)
                                (make-sphere 8)))

  See also: `cut`, `fuse`, `common`"
  (apply #'cl-occt:section (resolve-shape shape) (mapcar #'resolve-shape others)))

(defun translate (shape dx dy dz)
  "Translate (move) a shape by a vector.

  Designator may be a symbol, string, or raw shape.

  Example:

      (display :moved (translate (make-box 10 10 10) 20 0 0))

  See also: `rotate`"
  (cl-occt:translate (resolve-shape shape) dx dy dz))

(defun rotate (shape ax ay az angle-deg)
  "Rotate a shape around an axis by an angle in degrees.

  The axis is defined by the vector (AX, AY, AZ). Designator
  may be a symbol, string, or raw shape.

  Example:

      (display :rotated (rotate (make-box 10 10 10) 0 0 1 45))

  See also: `translate`"
  (cl-occt:rotate (resolve-shape shape) ax ay az angle-deg))

(defun make-prism (shape dx dy dz)
  "Extrude (prism) a face or wire along a vector.

  Designator may be a symbol, string, or raw shape.

  Example:

      (def :wire (make-wire (make-edge 0 0 10 0)
                            (make-edge 10 0 10 10)
                            (make-edge 10 10 0 10)
                            (make-edge 0 10 0 0)))
      (display :face (make-face :wire))
      (display :prism (make-prism :face 0 0 20))

  See also: `make-revol`"
  (cl-occt:make-prism (resolve-shape shape) dx dy dz))

(defun make-revol (shape ax ay az angle-deg)
  "Revolve a shape around an axis by an angle in degrees.

  Designator may be a symbol, string, or raw shape.

  Example:

      (display :revol (make-revol (make-face-on-plane
                                   (make-wire (make-circle2d 0 0 10))
                                   0 0 0 0 0 1)
                                  0 0 1 180))

  See also: `make-prism`"
  (cl-occt:make-revol (resolve-shape shape) ax ay az angle-deg))

(defun make-compound (shapes)
  "Create a compound shape from a list of shapes.

  Each element of SHAPES may be a symbol, string, or raw shape.

  Example:

      (display :assy (make-compound (list (make-box 10 10 10)
                                          (make-sphere 8))))

  See also: `make-part`"
  (cl-occt:make-compound (mapcar #'resolve-shape shapes)))

(defun make-part (shape &key name color location)
  "Create a part (top-level shape with metadata).

  NAME is a string, COLOR is a keyword or RGB triple,
  LOCATION is a gp_Trsf transformation.

  Example:

      (display :bolt (make-part (make-cylinder 5 20)
                                 :name \"M6 Bolt\"
                                 :color :cyan))

  See also: `make-compound`"
  (cl-occt:make-part (resolve-shape shape) :name name :color color :location location))

(defun write-step (shape filename)
  "Export a shape to STEP format.

  Designator may be a symbol, string, or raw shape.

  Example:

      (write-step :result \"output.step\")

  See also: `write-stl`"
  (cl-occt:write-step (resolve-shape shape) filename))

(defun write-stl (shape filename &key (deflection 0.1d0))
  "Export a shape to STL format.

  DEFLECTION controls mesh quality (smaller = finer mesh).
  Designator may be a symbol, string, or raw shape.

  Example:

      (write-stl :result \"output.stl\")
      (write-stl :result \"output.stl\" :deflection 0.01)

  See also: `write-step`"
  (cl-occt:write-stl (resolve-shape shape) filename :deflection deflection))
