(in-package :cl-occt-viewer)

(defun initialize-viewer (vwr)
  (%viewer-show-axis vwr 1)
  (%viewer-show-grid vwr 1)
  (%viewer-set-antialiasing vwr 1))

(defun start-viewer (&key (width 1024) (height 768) (title "cl-occt"))
  (when *viewer*
    (format t "Viewer is already running.~%")
    (return-from start-viewer nil))
  (setf *viewer-running* t)
  (let ((vwr (%viewer-create title width height)))
    (unless vwr
      (error "Failed to create viewer window"))
    (setf *viewer* vwr)
    (register-viewer-callbacks vwr)
    (%viewer-show vwr)
    (initialize-viewer vwr)
    (start-render-loop)
    (%viewer-run vwr)
    (stop-render-loop)
    (setf *viewer-running* nil)
    (setf *viewer* nil)))

(defun stop-viewer ()
  (when *viewer*
    (setf *viewer-running* nil)
    (%viewer-quit *viewer*)
    (setf *viewer* nil)))
