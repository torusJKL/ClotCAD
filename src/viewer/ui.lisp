(in-package :cl-occt-viewer)

(defvar *grid-visible* t)
(defvar *axis-visible* t)

(defun show-grid (&optional (show t))
  (%viewer-show-grid *viewer* (if show 1 0))
  (setf *grid-visible* (not (zerop (%viewer-is-grid-visible *viewer*)))))

(defun show-axis (&optional (show t))
  (%viewer-show-axis *viewer* (if show 1 0))
  (setf *axis-visible* (not (zerop (%viewer-is-axis-visible *viewer*)))))

(defun toggle-grid ()
  (show-grid (zerop (%viewer-is-grid-visible *viewer*))))

(defun toggle-axis ()
  (show-axis (zerop (%viewer-is-axis-visible *viewer*))))

(defun show-repl (&optional (show t))
  (%viewer-show-dock *viewer* "REPLPanel" (if show 1 0)))

(defun show-scene-tree (&optional (show t))
  (%viewer-show-dock *viewer* "SceneTreePanel" (if show 1 0)))

(defun toggle-repl ()
  (%viewer-show-dock *viewer* "REPLPanel" -1))

(defun toggle-scene-tree ()
  (%viewer-show-dock *viewer* "SceneTreePanel" -1))

(defun set-view-aa (enable)
  (%viewer-set-antialiasing *viewer* (if enable 1 0)))

(defun fit-view ()
  (%viewer-fit-all *viewer*))

(defun update-shape-count ()
  "Query shape counts from C++ and update the status bar."
  (when *viewer*
    (let* ((total (%viewer-get-shape-count *viewer*))
           (visible (%viewer-get-visible-shape-count *viewer*))
           (text (cond ((zerop total) "No shapes")
                       ((= visible 1) "Displaying 1 shape")
                       (t (format nil "Displaying ~D shapes" visible)))))
      (let ((hidden (- total visible)))
        (when (plusp hidden)
          (setf text (format nil "~A (~D hidden)" text hidden))))
      (%viewer-set-status-text *viewer* text))))

(cffi:defcallback %on-shape-visibility :void ((name :string) (visible :int))
  (declare (ignore name visible))
  (update-shape-count))

(defun register-shape-visibility-callback ()
  (when *viewer*
    (%viewer-set-visibility-callback *viewer* (cffi:callback %on-shape-visibility))))
