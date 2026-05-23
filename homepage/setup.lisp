(in-package :clotcad)

(asdf:load-system :staple-markdown)

(defclass clotcad-page (staple:simple-page) ())

(defmethod staple:page-type ((s (eql (asdf:find-system :clotcad))))
  'clotcad-page)

(defmethod staple:template ((s (eql (asdf:find-system :clotcad))))
  (asdf:system-relative-pathname :clotcad "homepage/default.ctml"))

(defmethod staple:packages ((s (eql (asdf:find-system :clotcad))))
  (mapcar #'find-package '(:clotcad :clotcad-user :cl-occt)))

(defmethod staple:images ((s (eql (asdf:find-system :clotcad))))
  (list (asdf:system-relative-pathname :clotcad "homepage/images/logo.svg")))

(defmethod staple:format-documentation ((ds string) (p clotcad-page))
  (let ((*package* (find-package :clotcad-user)))
    (staple:markup-code-snippets-ignoring-errors
     (staple:compile-source ds :markdown))))

(defmethod staple:template-data append ((p clotcad-page))
  (list :version (asdf:component-version (asdf:find-system :clotcad))))
