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

(defun set-antialiasing (enable)
  (%viewer-set-antialiasing *viewer* (if enable 1 0)))

(defun fit-all ()
  (%viewer-fit-all *viewer*))
