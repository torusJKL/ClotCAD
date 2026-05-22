(in-package :cl-occt-viewer)

(defvar *selected* (make-hash-table :test 'equal)
  "Set of selected shape names (string → t). Lisp is the source of truth.")

(defun select (&rest designators)
  "Select one or more shapes, replacing current selection.
Each designator is a string (\"box1\") or symbol (:box)."
  (let ((names (mapcar #'string designators)))
    (clrhash *selected*)
    (dolist (name names)
      (setf (gethash name *selected*) t))
    (queue-push :sync-selection)))

(defun deselect (&rest designators)
  "Remove one or more shapes from the current selection."
  (dolist (d designators)
    (remhash (string d) *selected*))
  (queue-push :sync-selection))

(defun clear-selection ()
  "Deselect all shapes."
  (clrhash *selected*)
  (queue-push :sync-selection))

(defun selected-shapes ()
  "Return a list of currently selected shape name strings."
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
Keyword values: :replace, :add, :remove, :xor, :clear, :replace-extra
OCCT constants:
  Aspect_VKeyMouse_LeftButton = 1<<13 = #x2000
  Aspect_VKeyFlags_SHIFT      = 1<<8  = #x100
  Aspect_VKeyFlags_CTRL       = 1<<9  = #x200
C++ computes: key = button | (modifiers << 16)"
  (when *viewer*
    (flet ((scheme-int (k)
             (or (cdr (assoc k cl-occt:*selection-scheme-map*)) 0)))
      (let ((left #x2000))
        (%viewer-set-mouse-selection-scheme *viewer* left (scheme-int click))
        (%viewer-set-mouse-selection-scheme *viewer* (logior left (ash #x200 16)) (scheme-int ctrl-click))
        (%viewer-set-mouse-selection-scheme *viewer* (logior left (ash #x100 16)) (scheme-int shift-click))))))


