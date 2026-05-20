(in-package :cl-occt-viewer)

(defvar *render-timer* nil
  "Periodic redraw timer handle.")

(defun start-render-loop (&key (interval 0.1))
  (when (and *viewer* (not *render-timer*))
    (setf *render-timer*
          (sb-thread:make-thread
           (lambda ()
             (loop while *viewer-running*
                   do (sleep interval)
                      (%viewer-redraw *viewer*)))
           :name "render-loop"))
    t))

(defun stop-render-loop ()
  (when *render-timer*
    (setf *render-timer* nil)
    t))
