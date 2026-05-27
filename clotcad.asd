(defsystem :clotcad
  :description "ClotCAD — parametric CAD with 3D viewer"
  :version "0.4.0"
  :author "Gal Buki"
  :license "GPLv3"
  :homepage "https://github.com/torusJKL/ClotCAD"
  :depends-on (:cl-occt :cffi :trivial-garbage :alexandria)
  :pathname "src/"
  :serial t
  :components
  ((:file "package")
   (:file "threading")
   (:module "model"
    :components
    ((:file "package")
     (:file "model")
     (:file "params")
     (:file "propagation")
     (:file "api")))
    (:module "viewer"
     :components
     ((:file "package")
      (:file "bindings")
      (:file "frame")
      (:file "queue")
       (:file "ops")
       (:file "select")
       (:file "query")
       (:file "repl")
      (:file "introspect")
     (:file "ui")
     (:file "theme")
     (:file "render")
     (:file "lifecycle")))))

(defsystem :clotcad/tests
  :description "Test suite for ClotCAD"
  :depends-on (:clotcad)
  :pathname "t/"
  :serial t
   :components
    ((:file "viewer-tests")
     (:file "query")
     (:file "frame")))
