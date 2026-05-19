;; Initialize Quicklisp for library dependencies
(require :asdf)
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))

(push (merge-pathnames #P"lib/cl-occt/" (truename "."))
      asdf:*central-registry*)
(push (truename ".") asdf:*central-registry*)

(asdf:load-system :cl-occt-viewer)
(in-package :cl-occt-viewer)

;; Start Swank in background thread for SLIME connectivity
(handler-case
    (progn
      (ql:quickload :swank :silent t)
      (let ((create-server (find-symbol "CREATE-SERVER" :swank)))
        (when create-server
          (sb-thread:make-thread
           (lambda ()
             (funcall create-server :port 4005 :dont-close t)
             (loop (sleep 1)))
           :name "cl-occt-slime")
          (format t ";; Swank server started on port 4005~%"))))
  (error (e)
    (format t ";; Warning: Could not start Swank: ~A~%" e)))

;; Start viewer (blocks main thread with Qt event loop)
(format t ";; Starting viewer...~%")
(start-viewer)
(sb-ext:quit)
