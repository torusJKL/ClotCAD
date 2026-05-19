(in-package :cl-occt-viewer)

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
    ;; Enter Qt event loop — blocks until viewer is quit
    (%viewer-run vwr)
    (setf *viewer-running* nil)
    (setf *viewer* nil)))

(defun stop-viewer ()
  (when *viewer*
    (setf *viewer-running* nil)
    (%viewer-quit *viewer*)
    (setf *viewer* nil)))
