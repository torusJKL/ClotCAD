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

(asdf:load-system :clotcad)
(in-package :clotcad-user)

;; Start Slynk in background thread for SLY connectivity
(ql:quickload :slynk :silent t)
(start-slynk :port 4005)

;; Start Alive LSP in background thread for LSP connectivity
(ql:quickload :alive-lsp :silent t)
(start-alive :port 4006)

;; Start viewer (blocks main thread with Qt event loop)
(format t ";; Starting viewer...~%")
(start-viewer)
(sb-ext:quit)
