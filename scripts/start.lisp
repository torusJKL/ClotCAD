;; Initialize Quicklisp for library dependencies
(require :asdf)
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))

(push (merge-pathnames #P"lib/cl-occt/" (truename "."))
      asdf:*central-registry*)
(push (merge-pathnames #P"lib/alive-lsp/" (truename "."))
      asdf:*central-registry*)
(push (truename ".") asdf:*central-registry*)

(asdf:load-system :cl-occt-viewer)
(in-package :cl-occt-user)

;; Start Slynk in background thread for SLY connectivity
(handler-case
    (progn
      (ql:quickload :slynk :silent t)
      (let ((bindings (find-symbol "*DEFAULT-WORKER-THREAD-BINDINGS*" :slynk))
            (create-server (find-symbol "CREATE-SERVER" :slynk)))
        (when (and bindings create-server)
          (setf (symbol-value bindings)
                `((*package* . ,(find-package :cl-occt-user))))
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
           :name "slynk")
          (format t ";; Slynk server started on port 4005~%"))))
  (error (e)
    (format t ";; Warning: Could not start Slynk: ~A~%" e)))

;; Start Alive LSP in background thread for LSP connectivity
(handler-case
    (progn
      (ql:quickload :alive-lsp :silent t)
      (let ((start (find-symbol "START" :alive/server)))
        (when start
          (sb-thread:make-thread
           (lambda ()
             (funcall start :port 4006 :default-package "CL-OCCT-USER"
                            :log-fn #'log-remote-eval)
             (loop (sleep 1)))
           :name "alive-lsp")
          (format t ";; Alive LSP server started on port 4006~%"))))
  (error (e)
    (format t ";; Warning: Could not start Alive LSP: ~A~%" e)))

;; Start viewer (blocks main thread with Qt event loop)
(format t ";; Starting viewer...~%")
(start-viewer)
(sb-ext:quit)
