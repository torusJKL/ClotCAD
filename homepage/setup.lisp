(in-package :clotcad)

(asdf:load-system :staple-markdown)

(defclass clotcad-page (staple:simple-page) ())

;; Import page slot symbols from STAPLE into the CLOTCAD package
;; so clip's standard-object method can find them when the page
;; object is pushed as a clipboard item (e.g. during page-siblings iteration).
(eval-when (:compile-toplevel :load-toplevel :execute)
  (shadowing-import 'staple:title :clotcad)
  (shadowing-import 'staple:language :clotcad)
  (shadowing-import 'staple:output :clotcad)
  (shadowing-import 'staple:project :clotcad))

(defmethod staple:page-type ((s (eql (asdf:find-system :clotcad))))
  'clotcad-page)

(defmethod staple:template ((s (eql (asdf:find-system :clotcad))))
  (asdf:system-relative-pathname :clotcad "homepage/default.ctml"))

(defmethod staple:packages ((s (eql (asdf:find-system :clotcad))))
  (mapcar #'find-package '(:clotcad :clotcad-user :cl-occt)))

(defmethod staple:subsystems ((system (eql (asdf:find-system :clotcad))))
  (remove (asdf:find-system :clotcad/tests) (call-next-method) :test #'eq))

(defmethod staple:documents ((s (eql (asdf:find-system :clotcad))))
  (list (asdf:system-relative-pathname :clotcad "README.md")))

(defmethod staple:images ((s (eql (asdf:find-system :clotcad))))
  (list (asdf:system-relative-pathname :clotcad "homepage/images/logo.svg")))

(defmethod staple:format-documentation ((ds string) (p clotcad-page))
  (let ((*package* (find-package :clotcad-user)))
    (staple:markup-code-snippets-ignoring-errors
     (staple:compile-source ds :markdown))))

(defmethod staple:template-data append ((p clotcad-page))
  (list :version (asdf:component-version (asdf:find-system :clotcad))))

(defparameter *cl-occt-commit*
  (or (string-trim '(#\Return #\Linefeed #\Space #\Tab)
                   (ignore-errors
                     (uiop:run-program
                      (list "git" "-C"
                            (uiop:native-namestring
                             (asdf:system-source-directory :clotcad))
                            "rev-parse" "HEAD:lib/cl-occt")
                      :output :string)))
      "HEAD"))

(defmethod staple:resolve-source-link :around (source (page clotcad-page))
  (if (and (listp source) (getf source :file))
      (let* ((cl-occt-root (asdf:system-relative-pathname :clotcad "lib/cl-occt/"))
             (source-file (getf source :file)))
        (if (and (probe-file cl-occt-root)
                 (pathname-utils:subpath-p (truename source-file)
                                           (truename cl-occt-root)))
            (format nil "https://github.com/torusJKL/cl-occt/blob/~a/~a~@[#L~a~]"
                    *cl-occt-commit*
                    (enough-namestring source-file cl-occt-root)
                    (getf source :row))
            (call-next-method)))
      (call-next-method)))
