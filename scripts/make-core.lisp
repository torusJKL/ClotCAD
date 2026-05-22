(require :asdf)
(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (load quicklisp-init)))

(push (merge-pathnames #P"lib/cl-occt/" (truename "."))
      asdf:*central-registry*)
(push (truename ".") asdf:*central-registry*)

(ql:quickload :cl-occt-viewer :silent t)
(ql:quickload :swank :silent t)

(sb-ext:save-lisp-and-die "ClotCAD.core"
  :purify t)
