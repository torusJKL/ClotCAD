(in-package :clotcad)

(defun initialize-viewer (vwr)
  (%viewer-show-axis vwr 0)
  (%viewer-show-grid vwr 1)
  (%viewer-set-antialiasing vwr 1)
  (apply-theme *theme-mode*)
  (register-color-scheme-callback)
  (apply-selection-schemes))

(defun start-viewer (&key (width 1024) (height 768) (title "ClotCAD"))
  "Launch the ClotCAD 3D viewer window.

  Creates the Qt window, initializes OCCT rendering, registers
  all callbacks (REPL, file I/O, selection), starts the render
  loop, and blocks until the window is closed. Only one viewer
  instance can run at a time.

  Example:

      (start-viewer)                                ;; default size
      (start-viewer :width 1920 :height 1080)        ;; full HD

  See also: `stop-viewer`, `bootstrap`"
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
  "Start all services: Slynk, Alive LSP, and the 3D viewer.

  This is the main entry point for the distribution. It starts
  Slynk on port 4005, Alive LSP on port 4006, and then blocks
  on the Qt event loop via `start-viewer`.

  Example:

      (clotcad:bootstrap)   ;; run from the distribution entry point

  See also: `start-viewer`, `stop-viewer`"
  (format t ";; Starting Slynk on port 4005...~%")
  (handler-case
      (let ((bindings (find-symbol "*DEFAULT-WORKER-THREAD-BINDINGS*" :slynk))
            (create-server (find-symbol "CREATE-SERVER" :slynk)))
        (if (and bindings create-server)
            (progn
              (setf (symbol-value bindings)
                    `((*package* . ,(find-package :clotcad-user))))
              (sb-thread:make-thread
               (lambda ()
                 (funcall create-server :port 4005 :dont-close t)
                 (loop
                   ;; Wrap mrepl-eval-1 once it's loaded (contrib loads on client connect)
                   (let ((sym (when (find-package :slynk-mrepl)
                                (find-symbol "MREPL-EVAL-1" :slynk-mrepl))))
                     (when (and sym (fboundp sym) (not (get sym :clotcad-wrapped)))
                       (setf (get sym :clotcad-wrapped) t)
                       (let ((orig (fdefinition sym)))
                         (setf (fdefinition sym)
                               (lambda (repl string)
                                 (let ((values (funcall orig repl string)))
                                   (let ((output (with-output-to-string (s)
                                                   (dolist (v values)
                                                     (format s "~S~%" v)))))
                                     (log-remote-eval string output))
                                   values))))))
                   (sleep 1)))
               :name "slynk"))
            (warn "Slynk not available; skipping.")))
    (error (e)
      (format t ";; Warning: Could not start Slynk: ~A~%" e)))
  (format t ";; Starting Alive LSP server on port 4006...~%")
  (handler-case
      (let ((start (find-symbol "START" :alive/server)))
        (if start
            (progn
              (sb-thread:make-thread
               (lambda ()
                 (funcall start :port 4006 :default-package "CL-OCCT-USER"
                                :log-fn #'log-remote-eval)
                 (loop (sleep 1)))
               :name "alive-lsp")
              (format t ";; Alive LSP server started on port 4006~%"))
            (warn "Alive LSP not available; skipping.")))
    (error (e)
      (format t ";; Warning: Could not start Alive LSP: ~A~%" e)))
  (format t ";; Starting viewer...~%")
  (start-viewer))

(defun stop-viewer ()
  "Stop the ClotCAD 3D viewer and close the window.

  Signals the render loop to stop and calls `%viewer-quit`
  to close the Qt window.

  Example:

      (stop-viewer)

  See also: `start-viewer`, `bootstrap`"
  (when *viewer*
    (setf *viewer-running* nil)
    (%viewer-quit *viewer*)
    (setf *viewer* nil)))
