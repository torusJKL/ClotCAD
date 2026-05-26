(in-package :clotcad)

(defun %print-lambda-list-item (item stream)
  (cond
    ((symbolp item)
     (if (char= #\& (char (symbol-name item) 0))
         (princ (symbol-name item) stream)
         (prin1 item stream)))
    ((listp item)
     (princ "(" stream)
     (loop for first = t then nil
           for sub in item
           do (unless first (princ " " stream))
              (%print-lambda-list-item sub stream))
     (princ ")" stream))
    (t
     (prin1 item stream))))

(defun %print-lambda-list (ll &optional (stream t))
  (princ "(" stream)
  (loop for first = t then nil
        for arg in ll
        do (unless first (princ " " stream))
           (%print-lambda-list-item arg stream))
  (princ ")" stream))

;; ---
;; doc
;; ---

(defun doc-impl (name)
  "Print documentation for the given symbol or function.

  Works with functions, macros, variables, types, structures, and
  CLOS classes.  Accepts a symbol, a string, or a function object.

  **Example:**

      (doc make-box)
      (doc \"make-box\")
      (doc #'make-box)

  **See also:** `apropos`"
  (let ((sym nil)
        (fn nil))
    (cond
      ((symbolp name)
       (setf sym name))
      ((stringp name)
       (setf sym (or (find-symbol (string-upcase name) *package*)
                     (find-symbol (string-upcase name) :clotcad)
                     (find-symbol (string-upcase name) :cl-occt)))
       (when (null sym)
         (format t "~&No symbol found for ~S~%" name)
         (return-from doc-impl nil)))
      ((functionp name)
       (setf fn name))
      (t
       (format t "~&doc: expected a symbol, string, or function, got ~S~%" name)
       (return-from doc-impl nil)))
    (let ((seen-header nil))
      (flet ((print-header ()
               (unless seen-header
                 (cond
                   (sym
                    (format t "~&~A/~A"
                            (package-name (symbol-package sym))
                            (symbol-name sym)))
                   (fn
                    (format t "~&~S" name))
                   (t
                    (format t "~&~S" name)))
                 (setf seen-header t)))
             (print-arglist (func)
               (let ((args (ignore-errors (sb-kernel:%fun-lambda-list func))))
                 (when (and args (not (eq args :unknown)))
                   (princ " " t)
                   (%print-lambda-list args)))))
        ;; Function / macro
        (when (or fn (and sym (or (fboundp sym) (macro-function sym))))
          (let* ((func (or fn (or (macro-function sym) (symbol-function sym))))
                 (docstr (documentation (or fn sym) 'function)))
            (when (or docstr func)
              (print-header)
              (print-arglist func)
              (terpri)
              (when (and docstr (not (string= docstr "")))
                (format t "  ~A~%" docstr)))))
        ;; Variable
        (when (and sym (boundp sym))
          (let ((docstr (documentation sym 'variable)))
            (when docstr
              (print-header)
              (format t "  [Variable]~%")
              (format t "  ~A~%" docstr))))
        ;; Type
        (when sym
          (let ((docstr (documentation sym 'type)))
            (when docstr
              (print-header)
              (format t "  [Type]~%")
              (format t "  ~A~%" docstr))))
        ;; Structure
        (when sym
          (let ((docstr (documentation sym 'structure)))
            (when docstr
              (print-header)
              (format t "  [Structure]~%")
              (format t "  ~A~%" docstr))))
        ;; CLOS class
        (when (and sym (find-class sym nil))
          (let ((docstr (documentation sym 'class)))
            (when docstr
              (print-header)
              (format t "  [Class]~%")
              (format t "  ~A~%" docstr))))
        ;; Nothing found
        (unless seen-header
          (if sym
              (format t "~&No documentation found for ~S~%" sym)
              (format t "~&No documentation found for ~S~%" (or fn name))))))
  (values)))

(defmacro doc (name)
  "Print documentation for the given symbol or function.

  A macro that quotes its argument so bare symbols work without
  explicit quoting.  Accepts a symbol, a string, or a function
  object created with #'.

  **Example:**

      (doc make-box)        ;; bare symbol — automatically quoted
      (doc \"make-box\")     ;; string — passed through
      (doc #'make-box)      ;; function object — passed through

  **See also:** `apropos`"
  (cond
    ((stringp name)
     `(doc-impl ,name))
    ((and (consp name) (member (car name) '(function quote)))
     `(doc-impl ,name))
    (t
     `(doc-impl ',name))))

;; ---
;; apropos
;; ---

(defun apropos-impl (pattern &key (packages nil packages-supplied-p) (case-insensitive t))
  "Search for symbols matching the given pattern.

  By default searches only CLOTCAD and CL-OCCT packages.

  - **pattern** a string or symbol to search for
  - **:packages** if `t`, search all packages; if a list of package
    names/designators, search those packages; if nil (default),
    search `:clotcad` and `:cl-occt`
  - **:case-insensitive** when t (default), match is case-insensitive

  **Example:**

      (apropos \"make\")
      (apropos \"def\" :packages t)
      (apropos \"map\" :packages '(:cl))

  **See also:** `doc`"
  (let* ((pattern-str (etypecase pattern
                         (string pattern)
                         (symbol (symbol-name pattern))))
         (target-packages
           (cond
             (packages-supplied-p
              (if (eq packages t)
                  (list-all-packages)
                  (mapcar #'find-package packages)))
             (t
              (list (find-package :clotcad) (find-package :cl-occt)))))
         (matches '()))
    (dolist (pkg target-packages)
      (when pkg
        (do-external-symbols (sym pkg)
          (let ((sym-name (symbol-name sym)))
            (when (if case-insensitive
                      (search (string-downcase pattern-str) (string-downcase sym-name))
                      (search pattern-str sym-name))
              (let ((cat (cond
                           ((macro-function sym) :macro)
                           ((fboundp sym) :function)
                           ((boundp sym) :variable)
                           ((find-class sym nil) :class)
                           (t :symbol))))
                (push (list sym cat) matches)))))))
    (setf matches (sort matches (lambda (a b)
                                  (let ((pkg-a (package-name (symbol-package (car a))))
                                        (pkg-b (package-name (symbol-package (car b))))
                                        (name-a (symbol-name (car a)))
                                        (name-b (symbol-name (car b))))
                                    (if (string= pkg-a pkg-b)
                                        (string-lessp name-a name-b)
                                        (string-lessp pkg-a pkg-b))))))
    (let ((printed? nil)
          (current-pkg nil))
      (dolist (match matches)
        (let* ((sym (car match))
               (cat (cadr match))
               (pkg (symbol-package sym)))
          (unless (eq pkg current-pkg)
            (setf current-pkg pkg)
            (format t "~&~A:~%" (package-name pkg)))
          (setf printed? t)
          (format t "  ~A (~(~A~))~%" (symbol-name sym) cat)))
      (unless printed?
        (format t "~&No matches found for ~S~%" pattern-str))))
  (values))

(defmacro apropos (pattern &key (packages nil packages-supplied-p) (case-insensitive t))
  "Search for symbols matching the given pattern.

  A macro that quotes its symbol argument so bare symbols work
  without explicit quoting.

  **Example:**

      (apropos box)              ;; bare symbol — automatically quoted
      (apropos \"make\")          ;; string — passed through
      (apropos \"def\" :packages t)

  **See also:** `doc`"
  (let ((quoted-pattern
          (cond
            ((stringp pattern) pattern)
            ((and (consp pattern) (member (car pattern) '(function quote)))
             pattern)
            (t `',pattern))))
    `(apropos-impl ,quoted-pattern
                   ,@(when packages-supplied-p `(:packages ,packages))
                   :case-insensitive ,case-insensitive)))


