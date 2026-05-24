(in-package :clotcad)

(defvar *selected* (make-hash-table :test 'equal)
  "Set of selected shape names (string → t). Lisp is the source of truth.")

(defun select (&rest designators)
  "Select one or more shapes, replacing current selection.

  Each designator is a string (\"box1\") or symbol (:box).

  - **designators** `&rest` of keywords or strings naming shapes to select

  **Example:**

      (select :box :sphere)
      (select \"box1\" \"sphere2\")
      (select)             ;; deselect all

  **See also:** `deselect`, `clear-selection`, `selected-shapes`"
  (let ((names (mapcar #'string designators)))
    (clrhash *selected*)
    (dolist (name names)
      (setf (gethash name *selected*) t))
    (queue-push :sync-selection)))

(defun deselect (&rest designators)
  "Remove one or more shapes from the current selection.

  - **designators** `&rest` of keywords or strings naming shapes to deselect

  **Example:**

      (deselect :sphere)
      (deselect \"box1\")

  **See also:** `select`, `clear-selection`"
  (dolist (d designators)
    (remhash (string d) *selected*))
  (queue-push :sync-selection))

(defun clear-selection ()
  "Deselect all shapes.

  **Example:**

      (clear-selection)

  **See also:** `select`, `deselect`"
  (clrhash *selected*)
  (queue-push :sync-selection))

(defun selected-shapes ()
  "Return a list of currently selected shape name strings.

  **Returns:** a list of string names.

  **Example:**

      (selected-shapes)   ;; => (\"BOX\" \"SPHERE\")

  **See also:** `select`, `deselect`"
  (loop for name being the hash-keys of *selected* collecting name))

(defun sync-selection-to-occt (&optional vwr)
  "Read *selected* and sync to OCCT context.
Must be called from the main thread (where OCCT context lives)."
  (let* ((viewer (or vwr *viewer*))
         (names (loop for k being the hash-keys of *selected* collect k))
         (count (length names)))
    (when (and viewer (plusp count))
      (cffi:with-foreign-object (buf :pointer count)
        (loop for i below count
              do (setf (cffi:mem-aref buf :pointer i)
                       (cffi:foreign-string-alloc (nth i names))))
        (%viewer-select-names viewer buf count)
        (loop for i below count
              do (cffi:foreign-string-free (cffi:mem-aref buf :pointer i))))
      (%viewer-redraw viewer))
    (when (and viewer (zerop count))
      (%viewer-select-names viewer (cffi:null-pointer) 0)
      (%viewer-redraw viewer))))

(defun apply-selection-schemes (&key (click :replace-extra)
                                      (ctrl-click :add)
                                      (shift-click :xor))
  "Configure mouse selection schemes from Lisp.

  - **click** scheme for plain click (default `:replace-extra`)
  - **ctrl-click** scheme for Ctrl+click (default `:add`)
  - **shift-click** scheme for Shift+click (default `:xor`)

  Keyword values: `:replace`, `:add`, `:remove`, `:xor`, `:clear`,
  `:replace-extra`.

  **Example:**

      (apply-selection-schemes)                           ;; defaults
      (apply-selection-schemes :click :add
                               :ctrl-click :xor)          ;; custom

  **See also:** `select`, `deselect`"
  (when *viewer*
    (flet ((scheme-int (k)
             (or (cdr (assoc k cl-occt:*selection-scheme-map*)) 0)))
      (let ((left #x2000))
        (%viewer-set-mouse-selection-scheme *viewer* left (scheme-int click))
        (%viewer-set-mouse-selection-scheme *viewer* (logior left (ash #x200 16)) (scheme-int ctrl-click))
        (%viewer-set-mouse-selection-scheme *viewer* (logior left (ash #x100 16)) (scheme-int shift-click))))))


