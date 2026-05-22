(in-package :cl-occt-viewer)

(defun initialize-viewer (vwr)
  (%viewer-show-axis vwr 0)
  (%viewer-show-grid vwr 1)
  (%viewer-set-antialiasing vwr 1)
  (apply-theme *theme-mode*)
  (register-color-scheme-callback)
  (apply-selection-schemes))

(defun start-viewer (&key (width 1024) (height 768) (title "ClotCAD"))
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



(defun bootstrap ()
  (format t ";; Starting Slynk on port 4005...~%")
  (handler-case
      (let ((bindings (find-symbol "*DEFAULT-WORKER-THREAD-BINDINGS*" :slynk))
            (create-server (find-symbol "CREATE-SERVER" :slynk)))
        (if (and bindings create-server)
            (progn
              (setf (symbol-value bindings)
                    `((*package* . ,(find-package :cl-occt-user))))
              (sb-thread:make-thread
               (lambda ()
                 (funcall create-server :port 4005 :dont-close t)
                 (loop (sleep 1)))
               :name "slynk"))
            (warn "Slynk not available; skipping.")))
    (error (e)
      (format t ";; Warning: Could not start Slynk: ~A~%" e)))
  (format t ";; Starting viewer...~%")
  (start-viewer))

(defun stop-viewer ()
  (when *viewer*
    (setf *viewer-running* nil)
    (%viewer-quit *viewer*)
    (setf *viewer* nil)))
