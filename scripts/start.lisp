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
             (loop (sleep 1)))
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
             (funcall start :port 4006 :default-package "CL-OCCT-USER")
             (loop (sleep 1)))
           :name "alive-lsp")
          (format t ";; Alive LSP server started on port 4006~%"))))
  (error (e)
    (format t ";; Warning: Could not start Alive LSP: ~A~%" e)))

;; Start viewer (blocks main thread with Qt event loop)
(format t ";; Starting viewer...~%")
(start-viewer)
(sb-ext:quit)
