(in-package :clotcad)

(defvar *grid-visible* t)
(defvar *axis-visible* nil)
(defvar *viewcube-visible* t)
(defvar *current-view* nil)

(defun show-grid (&optional (show t))
  "Show or hide the ground grid in the 3D viewport.

  Example:

      (show-grid nil)   ;; hide grid
      (show-grid t)     ;; show grid

  See also: `toggle-grid`, `show-axis`"
  (%viewer-show-grid *viewer* (if show 1 0))
  (setf *grid-visible* (not (zerop (%viewer-is-grid-visible *viewer*)))))

(defun show-axis (&optional (show t))
  "Show or hide the axis trihedron in the 3D viewport.

  Example:

      (show-axis nil)   ;; hide axis
      (show-axis t)     ;; show axis

  See also: `toggle-axis`, `show-grid`"
  (%viewer-show-axis *viewer* (if show 1 0))
  (setf *axis-visible* (not (zerop (%viewer-is-axis-visible *viewer*)))))

(defun toggle-grid ()
  "Toggle the ground grid on and off.

  Example:

      (toggle-grid)

  See also: `show-grid`"
  (show-grid (zerop (%viewer-is-grid-visible *viewer*))))

(defun toggle-axis ()
  "Toggle the axis trihedron on and off.

  Example:

      (toggle-axis)

  See also: `show-axis`"
  (show-axis (zerop (%viewer-is-axis-visible *viewer*))))

;; --- ViewCube ---

(defparameter *view-keyword-map*
  ;; OCCT Z-up convention (ViewCube default, no SetYup):
  ;;   Zup_Top    = V3d_Zpos  = 2  — looks at +Z face → shows X-Y plane
  ;;   Zup_Bottom = V3d_Zneg  = 5  — looks at -Z face → shows X-Y plane
  ;;   Zup_Front  = V3d_Yneg  = 4  — looks in -Y      → shows X-Z plane
  ;;   Zup_Back   = V3d_Ypos  = 1  — looks in +Y      → shows X-Z plane
  ;;   Zup_Left   = V3d_Xneg  = 3  — looks in -X      → shows Y-Z plane
  ;;   Zup_Right  = V3d_Xpos  = 0  — looks in +X      → shows Y-Z plane
  ;;   Zup_AxoRight = V3d_XposYnegZpos = 20
  '((:top    . 2)   ; Zup_Top    — looking at +Z face, X-Y plane
    (:bottom . 5)   ; Zup_Bottom — looking at -Z face
    (:front  . 4)   ; Zup_Front  — looking in -Y, X-Z plane
    (:back   . 1)   ; Zup_Back   — looking in +Y, X-Z plane
    (:left   . 3)   ; Zup_Left   — looking in -X, Y-Z plane
    (:right  . 0)   ; Zup_Right  — looking in +X, Y-Z plane
    (:iso    . 20))) ; Zup_AxoRight

(defun view-keyword->int (keyword)
  (let ((pair (assoc keyword *view-keyword-map*)))
    (if pair
        (cdr pair)
        (error "Unknown view orientation: ~S" keyword))))

(defun view-int->keyword (int)
  (let ((pair (rassoc int *view-keyword-map* :test #'=)))
    (if pair
        (car pair)
        nil)))

(defun show-viewcube (&optional (show t))
  "Show or hide the ViewCube in the 3D viewport.

  Example:

      (show-viewcube nil)   ;; hide ViewCube
      (show-viewcube t)     ;; show ViewCube

  See also: `toggle-viewcube`, `show-viewcube-axes`"
  (%viewer-show-viewcube *viewer* (if show 1 0))
  (setf *viewcube-visible* (not (zerop (%viewer-is-viewcube-visible *viewer*)))))

(defun toggle-viewcube ()
  "Toggle the ViewCube on and off.

  Example:

      (toggle-viewcube)

  See also: `show-viewcube`"
  (show-viewcube (zerop (%viewer-is-viewcube-visible *viewer*))))

(defun show-viewcube-axes (&optional (show t))
  "Show or hide the embedded trihedron axes inside the ViewCube.

  Example:

      (show-viewcube-axes nil)   ;; hide axes inside ViewCube

  See also: `show-viewcube`, `toggle-viewcube-axes`"
  (%viewer-set-viewcube-draw-axes *viewer* (if show 1 0)))

(defun toggle-viewcube-axes ()
  "Toggle the ViewCube's embedded trihedron axes.

  Example:

      (toggle-viewcube-axes)

  See also: `show-viewcube-axes`"
  (show-viewcube-axes (zerop (%viewer-get-viewcube-draw-axes *viewer*))))

(defun set-view (orientation)
  "Set the camera to a standard orientation.

  ORIENTATION is one of: `:top`, `:bottom`, `:front`, `:back`,
  `:left`, `:right`, `:iso`.

  Example:

      (set-view :top)    ;; looking down Z axis, X-Y plane
      (set-view :iso)    ;; isometric view
      (set-view :front)  ;; looking in -Y direction, X-Z plane

  See also: `current-view`"
  (let ((int-val (view-keyword->int orientation)))
    (%viewer-set-view *viewer* int-val)
    (setf *current-view* orientation)))

(defun current-view ()
  "Return the current camera orientation keyword, or NIL.

  Returns one of: `:top`, `:bottom`, `:front`, `:back`,
  `:left`, `:right`, `:iso`, or NIL if the orientation
  does not match a standard view.

  Example:

      (current-view)   ;; => :TOP (or NIL)

  See also: `set-view`"
  (let ((int-val (%viewer-get-view-orientation *viewer*)))
    (or (view-int->keyword int-val)
        (progn
          (setf *current-view* nil)
          nil))))

(defun show-repl (&optional (show t))
  "Show or hide the REPL dock panel.

  Example:

      (show-repl nil)   ;; hide REPL
      (show-repl t)     ;; show REPL

  See also: `toggle-repl`, `show-scene-tree`"
  (%viewer-show-dock *viewer* "REPLPanel" (if show 1 0)))

(defun show-scene-tree (&optional (show t))
  "Show or hide the Scene Tree dock panel.

  Example:

      (show-scene-tree nil)   ;; hide Scene Tree
      (show-scene-tree t)     ;; show Scene Tree

  See also: `toggle-scene-tree`, `show-repl`"
  (%viewer-show-dock *viewer* "SceneTreePanel" (if show 1 0)))

(defun toggle-repl ()
  "Toggle the REPL dock panel on and off.

  Example:

      (toggle-repl)

  See also: `show-repl`"
  (%viewer-show-dock *viewer* "REPLPanel" -1))

(defun toggle-scene-tree ()
  "Toggle the Scene Tree dock panel on and off.

  Example:

      (toggle-scene-tree)

  See also: `show-scene-tree`"
  (%viewer-show-dock *viewer* "SceneTreePanel" -1))

(defun set-view-aa (enable)
  "Enable or disable multi-sample anti-aliasing (MSAA).

  Example:

      (set-view-aa t)     ;; enable AA
      (set-view-aa nil)   ;; disable AA

  See also: `fit-view`"
  (%viewer-set-antialiasing *viewer* (if enable 1 0)))

(defun fit-view ()
  "Fit all displayed shapes into the current viewport.

  Adjusts the camera distance so all shapes are visible.

  Example:

      (fit-view)

  See also: `set-view`"
  (%viewer-fit-all *viewer*))

(defun update-shape-count ()
  "Read shape counts from *displayed-models* and update the status bar."
  (when *viewer*
    (let* ((total (hash-table-count *displayed-models*))
           (visible (loop for v being the hash-values of *displayed-models*
                          count (second v)))
           (text (cond ((zerop total) "No shapes")
                       ((= visible 1) "Displaying 1 shape")
                       (t (format nil "Displaying ~D shapes" visible)))))
      (let ((hidden (- total visible)))
        (when (plusp hidden)
          (setf text (format nil "~A (~D hidden)" text hidden))))
      (%viewer-set-status-text *viewer* text))))

(cffi:defcallback %on-shape-visibility :void ((name :string) (visible :int))
  (let ((entry (gethash name *displayed-models*)))
    (when entry
      (setf (second entry) (not (zerop visible)))))
  (update-shape-count))

(defun register-shape-visibility-callback ()
  (when *viewer*
    (%viewer-set-visibility-callback *viewer* (cffi:callback %on-shape-visibility))))

(cffi:defcallback %on-selection-changed :void ()
  "Called from C++ when selection changes (3D view or scene tree).
Reads OCCT context and updates *selected* to match."
  (let ((vwr *viewer*)
        (new (make-hash-table :test 'equal)))
    (when vwr
      (maphash (lambda (name _)
                 (when (not (zerop (%viewer-is-shape-selected vwr name)))
                   (setf (gethash name new) t)))
               *displayed-models*)
      (setf *selected* new))))

(defun register-selection-callback ()
  (when *viewer*
    (%viewer-set-selection-callback *viewer* (cffi:callback %on-selection-changed))))

(cffi:defcallback %on-viewcube-orientation :void ((orientation :int))
  (let ((keyword (view-int->keyword orientation)))
    (setf *current-view* keyword)))

(defun register-viewcube-callback ()
  (when *viewer*
    (%viewer-set-viewcube-callback *viewer* (cffi:callback %on-viewcube-orientation))))
