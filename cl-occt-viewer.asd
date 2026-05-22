(defsystem :cl-occt-viewer
  :description "Qt-based 3D viewer for cl-occt using OCCT AIS"
  :version "0.1.0"
  :author "Gal Buki"
  :license "GPLv3"
  :depends-on (:cl-occt :cffi :trivial-garbage :alexandria)
  :pathname "src/"
  :serial t
  :components
   ((:module "viewer"
     :components
        ((:file "package")
         (:file "bindings")
         (:file "queue")
         (:file "ops")
         (:file "select")
         (:file "repl")
        (:file "ui")
        (:file "theme")
        (:file "render")
        (:file "lifecycle")))))

(defsystem :cl-occt-viewer/tests
  :description "Test suite for cl-occt-viewer"
  :depends-on (:cl-occt-viewer)
  :pathname "t/"
  :serial t
  :components
  ((:file "viewer-tests")))
