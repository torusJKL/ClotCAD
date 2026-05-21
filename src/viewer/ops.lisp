(in-package :cl-occt-viewer)

(defvar *show-defs-in-tree* t
  "When non-nil, def-ined shapes appear in the Scene Tree.
   When nil, they are hidden from the tree but can still be operated on.")

(defun resolve-shape (designator)
  (etypecase designator
    (cl-occt:shape designator)
    (string (let ((entry (gethash designator *displayed-models*)))
              (if entry
                  (first entry)
                  (error "~S does not name a known shape" designator))))
    (symbol (let ((entry (gethash (string designator) *displayed-models*)))
              (if entry
                  (first entry)
                  (let ((m (gethash designator cl-occt.impl:*model-registry*)))
                    (if m
                        (cl-occt.impl:model-cached-shape m)
                        (error "~S does not name a known shape" designator))))))))

(defmacro def (name shape-form)
  `(let* ((shape ,shape-form)
          (sname (string ',name)))
     (display ',name shape
              :visible nil
              :show-in-tree *show-defs-in-tree*
              :origin :def)
     shape))

(defun show (&rest names)
  (dolist (name names)
    (let* ((sname (string name))
           (entry (gethash sname *displayed-models*)))
      (if entry
          (progn
            (setf (second entry) t)
            (queue-push :sync))
          (error "~S is not currently displayed" name)))))

(defun hide (&rest names)
  (dolist (name names)
    (let* ((sname (string name))
           (entry (gethash sname *displayed-models*)))
      (if entry
          (progn
            (setf (second entry) nil)
            (queue-push :sync))
          (error "~S is not currently displayed" name)))))

(defun toggle (&rest names)
  (dolist (name names)
    (let* ((sname (string name))
           (entry (gethash sname *displayed-models*)))
      (if entry
          (progn
            (setf (second entry) (not (second entry)))
            (queue-push :sync))
          (error "~S is not currently displayed" name)))))

(defun show-defs (on)
  (setf *show-defs-in-tree* on)
  (maphash (lambda (name entry)
             (when (eq (fifth entry) :def)
               (setf (third entry) on)))
           *displayed-models*)
  (queue-push :sync))

(defun toggle-defs ()
  (show-defs (not *show-defs-in-tree*)))

;; --- Wrapper functions ---

(defun cut (shape &rest others)
  (apply #'cl-occt:cut (resolve-shape shape) (mapcar #'resolve-shape others)))

(defun fuse (shape &rest others)
  (apply #'cl-occt:fuse (resolve-shape shape) (mapcar #'resolve-shape others)))

(defun common (shape &rest others)
  (apply #'cl-occt:common (resolve-shape shape) (mapcar #'resolve-shape others)))

(defun section (shape &rest others)
  (apply #'cl-occt:section (resolve-shape shape) (mapcar #'resolve-shape others)))

(defun translate (shape dx dy dz)
  (cl-occt:translate (resolve-shape shape) dx dy dz))

(defun rotate (shape ax ay az angle-deg)
  (cl-occt:rotate (resolve-shape shape) ax ay az angle-deg))

(defun make-prism (shape dx dy dz)
  (cl-occt:make-prism (resolve-shape shape) dx dy dz))

(defun make-revol (shape ax ay az angle-deg)
  (cl-occt:make-revol (resolve-shape shape) ax ay az angle-deg))

(defun make-compound (shapes)
  (cl-occt:make-compound (mapcar #'resolve-shape shapes)))

(defun make-part (shape &key name color location)
  (cl-occt:make-part (resolve-shape shape) :name name :color color :location location))

(defun write-step (shape filename)
  (cl-occt:write-step (resolve-shape shape) filename))

(defun write-stl (shape filename &key (deflection 0.1d0))
  (cl-occt:write-stl (resolve-shape shape) filename :deflection deflection))
