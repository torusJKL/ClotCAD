(in-package :clotcad)

(defvar *alive-server* nil
  "Handle to the Alive LSP server instance, used for graceful shutdown.")

(defparameter *pending-port-errors* nil
  "List of error message strings for port conflicts. Displayed as Qt dialogs
in INITIALIZE-VIEWER after the viewer window exists.")

(defun initialize-viewer (vwr)
  (%viewer-show-axis vwr 0)
  (%viewer-show-grid vwr 1)
  (%viewer-set-antialiasing vwr 1)
  (apply-theme *theme-mode*)
  (register-color-scheme-callback)
  (apply-selection-schemes)
  ;; Show pending port conflict dialogs (single dialog with combined message)
  (when *pending-port-errors*
    (%viewer-show-message vwr "Port In Use"
                          (with-output-to-string (s)
                            (dolist (msg *pending-port-errors*)
                              (format s "~A~%~%" msg))))
    (setf *pending-port-errors* nil))
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
  ;; Pre-check port before spawning thread
  (handler-case
      (let ((socket (make-instance 'sb-bsd-sockets:inet-socket :type :stream :protocol :tcp)))
        (setf (sb-bsd-sockets:sockopt-reuse-address socket) t)
        (sb-bsd-sockets:socket-bind socket #(127 0 0 1) port)
        (sb-bsd-sockets:socket-close socket))
    (sb-bsd-sockets:address-in-use-error (e)
      (declare (ignore e))
      (push (format nil "Port ~D is already in use.~%Slynk REPL server cannot be started." port)
            *pending-port-errors*)
      (format t ";; Warning: Could not start Slynk: port ~D already in use~%" port)
      (return-from start-slynk nil)))
  (handler-case
      (let ((bindings (find-symbol "*DEFAULT-WORKER-THREAD-BINDINGS*" :slynk))
            (create-server (find-symbol "CREATE-SERVER" :slynk)))
        (if (and bindings create-server)
            (progn
              (setf (symbol-value bindings)
                    `((*package* . ,(find-package :clotcad-user))))
              (sb-thread:make-thread
               (lambda ()
                 (handler-case
                     (progn
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
                   (sb-bsd-sockets:address-in-use-error (e)
                     (declare (ignore e))
                     (format t ";; Warning: Slynk port ~D already in use (detected in thread)~%" port))))
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
  ;; Pre-check port before spawning thread (soft dependency on usocket)
  (let ((usocket-pkg (find-package :usocket)))
    (when usocket-pkg
      (let ((listen-sym (find-symbol "SOCKET-LISTEN" usocket-pkg))
            (close-sym (find-symbol "SOCKET-CLOSE" usocket-pkg)))
        (when (and listen-sym close-sym)
          (multiple-value-bind (socket err)
              (ignore-errors (funcall listen-sym "127.0.0.1" port :reuse-address t))
            (if err
                (progn
                  (push (format nil "Port ~D is already in use.~%Alive LSP server cannot be started." port)
                        *pending-port-errors*)
                  (format t ";; Warning: Could not start Alive LSP: port ~D already in use~%" port)
                  (return-from start-alive nil))
                (funcall close-sym socket)))))))
  (handler-case
      (let ((start-srv (find-symbol "START-SERVER" :alive/server))
            (make-inst (find-symbol "MAKE-INSTANCE" :alive/server))
            (lsp-server (find-symbol "LSP-SERVER" :alive/server))
            (log-create (find-symbol "CREATE" :alive/logger))
            (log-info (find-symbol "*INFO*" :alive/logger)))
        (if (and start-srv make-inst lsp-server log-create log-info)
            (let* ((log (funcall log-create *standard-output* (symbol-value log-info)))
                   (server (funcall make-inst lsp-server)))
              (setf *alive-server* server)
              (funcall start-srv server log port "CLOTCAD-USER" #'log-remote-eval)
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
    (lambda (s) (declare (ignore s)) (sb-ext:exit :code 0)))
  (handler-case (loop (sleep 1))
    (sb-sys:interactive-interrupt () (sb-ext:exit :code 0))))

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

(defun quit-clotcad ()
  "Stop all ClotCAD services and exit the Lisp process.

  Stops the Slynk server, Alive LSP server, and 3D viewer (if
  running), resets Lisp state, and calls `sb-ext:quit` to exit
  cleanly. Works in all modes: `--viewer`, `--slynk`, `--alive`.

  **Example:**

      (quit-clotcad)

  **See also:** `stop-viewer`, `bootstrap`"
  (format t ";; Quitting ClotCAD...~%")

  ;; 1. Schedule a deferred shutdown so the eval response reaches
  ;;    the remote client before the process terminates. The viewer
  ;;    and state reset are done here too — doing them inline would
  ;;    unblock the main thread (in --viewer mode) which then calls
  ;;    sb-ext:quit from run.sh before the response is sent.
  (sb-thread:make-thread
   (lambda ()
     (sleep 0.1)
     (when *viewer*
       (stop-render-loop)
       (%viewer-quit *viewer*)
       (%viewer-destroy *viewer*)
       (setf *viewer* nil)
       (setf *viewer-running* nil)
       (setf *viewer-queue* nil))
     (setf *repl-log* nil
           *repl-accumulator* ""
           *import-forms* nil
           *import-cancelled* nil)
     (clrhash *displayed-models*)
     (clrhash *selected*)
     (sb-ext:quit))
   :name "quit-clotcad-exit")
  "Goodbye!")
