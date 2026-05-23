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

(ql:quickload :cl-occt-viewer :silent t)
(ql:quickload :slynk :silent t)
(ql:quickload :alive-lsp :silent t)

;; Pre-load all SLY contrib systems so they're in memory and ASDF
;; never needs to access the build machine's FASL cache at runtime.
(ql:quickload '(:slynk/mrepl :slynk/indentation :slynk/arglists
                :slynk/fancy-inspector :slynk/package-fu
                :slynk/profiler :slynk/stickers :slynk/trace-dialog
                :slynk/retro)
              :silent t)
;; Register modules in *modules* so slynk-loader:require-module
;; (called by slynk-require when SLY connects) finds them without
;; trying to compile source from the build machine's Quicklisp path.
(dolist (module '(:slynk/mrepl :slynk/indentation :slynk/arglists
                  :slynk/fancy-inspector :slynk/package-fu
                  :slynk/profiler :slynk/stickers :slynk/trace-dialog
                  :slynk/retro))
  (pushnew (string-upcase module) *modules* :test #'equal))

(sb-ext:save-lisp-and-die "ClotCAD.core"
  :purify t)
