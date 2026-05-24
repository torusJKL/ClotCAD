(in-package :clotcad)

(defun initialize-viewer (vwr)
  (%viewer-show-axis vwr 0)
  (%viewer-show-grid vwr 1)
  (%viewer-set-antialiasing vwr 1)
  (apply-theme *theme-mode*)
  (register-color-scheme-callback)
  (apply-selection-schemes)
  ;; Register viewer-refresh on the propagation hook
  (push 'viewer-refresh *after-propagation-hook*))

(defun start-viewer (&key (width 1024) (height 768) (title "ClotCAD"))
  "Launch the ClotCAD 3D viewer window.

  Creates the Qt window, initializes OCCT rendering, registers
  all callbacks (REPL, file I/O, selection), starts the render
  loop, and blocks until the window is closed. Only one viewer
  instance can run at a time.

  - **width** optional window width in pixels (default 1024)
  - **height** optional window height in pixels (default 768)
  - **title** optional window title string (default \"ClotCAD\")

  **Returns:** `nil` when the viewer window is closed.

  **Example:**

      (start-viewer)                                ;; default size
      (start-viewer :width 1920 :height 1080)        ;; full HD

  **See also:** `stop-viewer`, `bootstrap`"
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



(defun start-slynk (&key (port 4005))
  "Start the Slynk server on the given PORT in a dedicated thread.
Returns T if started, NIL if Slynk is not available.

**Example:**

    (start-slynk)                ;; port 4005
    (start-slynk :port 4007)     ;; custom port

**See also:** `start-alive`, `bootstrap`"
  (format t ";; Starting Slynk on port ~D...~%" port)
  (handler-case
      (let ((bindings (find-symbol "*DEFAULT-WORKER-THREAD-BINDINGS*" :slynk))
            (create-server (find-symbol "CREATE-SERVER" :slynk)))
        (if (and bindings create-server)
            (progn
              (setf (symbol-value bindings)
                    `((*package* . ,(find-package :clotcad-user))))
              (sb-thread:make-thread
               (lambda ()
                 (funcall create-server :port port :dont-close t)
                 (loop
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
               :name "slynk")
              t)
            (warn "Slynk not available; skipping.")))
    (error (e)
      (format t ";; Warning: Could not start Slynk: ~A~%" e))))

(defun start-alive (&key (port 4006))
  "Start the Alive LSP server on the given PORT in a dedicated thread.
Returns T if started, NIL if Alive LSP is not available.

**Example:**

    (start-alive)                ;; port 4006
    (start-alive :port 4008)     ;; custom port

**See also:** `start-slynk`, `bootstrap`"
  (format t ";; Starting Alive LSP server on port ~D...~%" port)
  (handler-case
      (let ((start (find-symbol "START" :alive/server)))
        (if start
            (progn
              (sb-thread:make-thread
               (lambda ()
                 (funcall start :port port :default-package "CL-OCCT-USER"
                                :log-fn #'log-remote-eval)
                 (loop (sleep 1)))
               :name "alive-lsp")
              (format t ";; Alive LSP server started on port ~D~%" port)
              t)
            (warn "Alive LSP not available; skipping.")))
    (error (e)
      (format t ";; Warning: Could not start Alive LSP: ~A~%" e))))

(defun wait-forever ()
  "Block the current thread indefinitely until interrupted.
Installs a low-level SIGINT handler so that Ctrl+C exits cleanly
even when other libraries (e.g. Slynk) try to intercept the
signal. The handler-case provides a fallback for the condition-
based delivery path.

**Example:**

    (wait-forever)   ;; blocks until Ctrl+C

**See also:** `start-slynk`, `start-alive`"
  (sb-sys:enable-interrupt sb-unix:sigint
    (lambda (s) (declare (ignore s)) (sb-ext:exit 0)))
  (handler-case (loop (sleep 1))
    (sb-sys:interactive-interrupt () (sb-ext:exit 0))))

(defun bootstrap ()
  "Start all services: Slynk, Alive LSP, and the 3D viewer.

  This is the main entry point for the distribution. It starts
  Slynk on port 4005, Alive LSP on port 4006, and then blocks
  on the Qt event loop via `start-viewer`.

  **Example:**

      (clotcad:bootstrap)   ;; run from the distribution entry point

  **See also:** `start-viewer`, `stop-viewer`, `start-slynk`, `start-alive`"
  (start-slynk :port 4005)
  (start-alive :port 4006)
  (format t ";; Starting viewer...~%")
  (start-viewer))

(defun stop-viewer ()
  "Stop the ClotCAD 3D viewer and close the window.

  Signals the render loop to stop and calls `%viewer-quit`
  to close the Qt window.

  **Example:**

      (stop-viewer)

  **See also:** `start-viewer`, `bootstrap`"
  (when *viewer*
    (setf *viewer-running* nil)
    (%viewer-quit *viewer*)
    (setf *viewer* nil)))
