(in-package :clotcad)

(defun %print-lambda-list-item (item stream)
  (cond
    ((symbolp item)
     (cond
       ((char= #\& (char (symbol-name item) 0))
        (princ (symbol-name item) stream))
       ((keywordp item)
        (princ ":" stream)
        (princ (symbol-name item) stream))
       (t
        (princ (symbol-name item) stream))))
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

  **See also:** `browse`"
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

  **See also:** `browse`"
  (cond
    ((stringp name)
     `(doc-impl ,name))
    ((and (consp name) (member (car name) '(function quote)))
     `(doc-impl ,name))
    (t
     `(doc-impl ',name))))

;; ---
;; Category infrastructure
;; ---

(defparameter *category-display-names*
  '((:primitives . "Primitives")
    (:booleans . "Booleans")
    (:fillet . "Fillets")
    (:chamfer . "Chamfers")
    (:transforms . "Transforms")
    (:sweep . "Sweeps")
    (:loft . "Loft")
    (:faces . "Construction")
    (:topology . "Topology")
    (:compounds . "Compounds")
    (:assembly . "Assembly")
    (:blend . "Blends")
    (:draft . "Draft")
    (:offset . "Offsets")
    (:shell . "Shell")
    (:helix . "Helix")
    (:hole-prism-revol . "Features")
    (:local-ops . "Local Operations")
    (:pipe-feature . "Pipe")
    (:face-filling . "Face Filling")
    (:shape-fix . "Shape Fix")
    (:shape-process . "Shape Processing")
    (:shape-rebuild . "Shape Conversion")
    (:mass-properties . "Mass Properties")
    (:shape-analysis . "Shape Analysis")
    (:geom2d . "2D Geometry")
    (:curves . "Curves")
    (:surfaces . "Surfaces")
    (:geom-algorithms . "Geometric Algorithms")
    (:text . "Text")
    (:io . "File I/O")
    (:errors . "Error Handling")
    (:shape . "Shape")
    (:viewer . "Viewer")
    (:viewer-background . "Background")
    (:viewer-camera . "Camera")
    (:viewer-colors . "Colors")
    (:viewer-defaults . "Viewer Defaults")
    (:viewer-dimensions . "Dimensions")
    (:viewer-drawer . "Drawer")
    (:viewer-grid . "Grid")
    (:viewer-lighting . "Lighting")
    (:viewer-object-props . "Object Properties")
    (:viewer-rendering . "Rendering")
    (:viewer-text-labels . "Text Labels")
    (:graphic3d . "Graphic3D")
    (:ocaf . "OCAF")
    (:xcaf . "XCAF")
    (:shape-utilities . "Shape Utilities")
    (:advanced-modeling . "Advanced Modeling")
    (:materials-texture . "Materials & Texture")
    (:meshing . "Meshing")
    (:2d-constraints . "2D Constraints")
    (:animation . "Animation")
    (:normal-project . "Normal Projection")
    (:transfer-params . "Transfer Parameters")
    (:selection . "Selection (OCCT)")
    (:queue . "Queue")
    (:ops . "Viewer Ops")
    (:select . "Selection")
    (:ui . "UI")
    (:render . "Render")
    (:repl . "REPL")
    (:theme . "Theme")
    (:lifecycle . "Lifecycle")
    (:introspect . "Introspection")
    (:model . "Model")
    (:params . "Params")
    (:propagation . "Propagation")
    (:api . "Parametric API")))

(defparameter *category-merge-groups*
  '((:booleans :bop-splitter :bop-utilities :bop-volume)
    (:io :brep-io :rwstl-io)
    (:primitives :wedge-primitive)
    (:shape-analysis :find-edges :inttools :hlr :gcpnts-points
                     :geometry-evaluation :subshape-properties
                     :surface-curve-local-props)
    (:topology :topology-data-access)
    (:assembly :assembly-location)
    (:graphic3d :graphic3d-aspects :graphic3d-clip-plane :graphic3d-group
                :graphic3d-rendering-params :graphic3d-shader-program
                :graphic3d-structure :prs3d-tools :viewer-ais-types)
    (:ocaf :ocaf-attributes :ocaf-functions :ocaf-label-tree :ocaf-naming)
    (:xcaf :xcaf-dimtol :xcaf-doc)
    (:shape-utilities :shape-check :shape-conversion :shape-copy
                      :shape-tolerance :small-faces :sewing :defeaturing
                      :remove-features)
    (:advanced-modeling :advanced-surface-filling :fair-curve :drafted-prism)
    (:materials-texture :materials :texture)
    (:meshing :mesh)
    (:2d-constraints :constrained-2d :expression-interp))
  "List of merge groups. Each entry is (TARGET &rest SOURCES) where
  TARGET and SOURCES are keyword symbols matching source-file stems.
  Functions from SOURCES stems are merged into the TARGET stem's
  category, and SOURCE stems are removed from the index.")

(defvar *category-fn-index* nil
  "Cached mapping of category stem → list of function symbols.
  Built lazily by %ensure-category-index.")

(defun %try-load-sb-introspect ()
  (ignore-errors (require :sb-introspect))
  (find-package :sb-introspect))

(defun %category-display-name (stem)
  (let ((key (intern (string-upcase stem) :keyword)))
    (or (cdr (assoc key *category-display-names*))
        (string-capitalize stem))))

(defun %build-category-index (&key (packages t))
  (unless (%try-load-sb-introspect)
    (return-from %build-category-index (make-hash-table :test 'equal)))
  (let* ((find-src (find-symbol "FIND-DEFINITION-SOURCE" :sb-introspect))
         (get-path (find-symbol "DEFINITION-SOURCE-PATHNAME" :sb-introspect))
         (index (make-hash-table :test 'equal)))
    (unless (and find-src get-path)
      (return-from %build-category-index index))
    (flet ((scan-package (pkg)
             (do-external-symbols (sym pkg)
               (when (fboundp sym)
                 (let ((fn (or (macro-function sym) (symbol-function sym))))
                   (handler-case
                       (let* ((src (funcall find-src fn))
                              (path (when src (funcall get-path src)))
                              (stem (when path (pathname-name path))))
                         (when stem
                           (pushnew sym (gethash stem index))))
                     (error () nil)))))))
      (if (eq packages t)
          (progn
            (scan-package (find-package :cl-occt))
            (scan-package (find-package :clotcad)))
          (dolist (p packages)
            (let ((pkg (find-package p)))
              (when pkg
                (scan-package pkg))))))
    (maphash (lambda (stem fns)
               (setf (gethash stem index)
                     (sort fns (lambda (a b)
                                 (string-lessp (symbol-name a) (symbol-name b))))))
             index)
    (%apply-merge-groups index)
    index))

(defun %apply-merge-groups (index)
  (dolist (group *category-merge-groups*)
    (destructuring-bind (target . sources) group
      (let* ((target-key (string-downcase target))
             (merged (gethash target-key index)))
        (dolist (source sources)
          (let ((source-key (string-downcase source)))
            (multiple-value-bind (source-fns found)
                (gethash source-key index)
              (when found
                (setf merged (union merged source-fns :test #'eq))
                (remhash source-key index)))))
        (when merged
          (setf (gethash target-key index)
                (sort merged #'string-lessp))))))
  index)

(defun %ensure-category-index (&key (packages t))
  (or *category-fn-index*
      (setf *category-fn-index* (%build-category-index :packages packages))))

(defun %rebuild-category-index ()
  (setf *category-fn-index* nil))

(defun %coerce-packages (packages)
  (cond
    ((null packages) nil)
    ((eq packages t) t)
    ((listp packages) packages)
    (t (list packages))))

(defun %find-categories (keyword &optional (index *category-fn-index*))
  (let ((pattern (string-downcase (symbol-name keyword)))
        (matches '()))
    (maphash (lambda (stem fns)
               (let ((display (%category-display-name stem)))
                 (when (or (search pattern (string-downcase display))
                           (search pattern (string-downcase stem)))
                   (push (list display stem fns) matches))))
             index)
    (sort matches (lambda (a b) (string-lessp (first a) (first b))))))

(defun %print-category-tree (&key (stream t) (index *category-fn-index*))
  (unless (find-package :sb-introspect)
    (format stream "~&sb-introspect not available — cannot build category index~%")
    (return-from %print-category-tree nil))
  (let ((compact (typep *standard-output* 'string-stream)))
    (format stream "~&── ClotCAD Capabilities (by source) ────────────────────~2%")
    (let ((sorted-categories '()))
      (maphash (lambda (stem fns)
                 (push (list (%category-display-name stem) stem fns) sorted-categories))
               index)
      (setf sorted-categories
            (sort sorted-categories (lambda (a b) (string-lessp (first a) (first b)))))
      (dolist (cat sorted-categories)
        (let ((display (first cat))
              (fns (third cat)))
          (if compact
              (format stream "  ~A~40T~2D~%" display (length fns))
              (progn
                (format stream "  ~A~40T~2D — " display (length fns))
                (let ((names (mapcar (lambda (s) (string-downcase (symbol-name s)))
                                     (subseq fns 0 (min 5 (length fns))))))
                  (if (> (length fns) 5)
                      (format stream "~{~A, ~}...~%" names)
                      (format stream "~{~A, ~}~%" names)))))))
      (format stream "~%  Details: (browse :<category>)")
      (format stream "  Search:  (browse <pattern>)~%"))
    t))

(defun %get-fn-arglist (fn)
  ;; 1. Try sb-introspect:function-arglist (public API)
  (let ((get-args (and (find-package :sb-introspect)
                       (find-symbol "FUNCTION-ARGLIST" :sb-introspect))))
    (when get-args
      (let ((result (handler-case (funcall get-args fn)
                      (error () :error))))
        (unless (or (null result) (eq result :error))
          (return-from %get-fn-arglist result)))))
  ;; 2. Try sb-kernel:%fun-lambda-list (internal but fast)
  (let ((result (ignore-errors (sb-kernel:%fun-lambda-list fn))))
    (unless (or (null result) (eq result :unknown))
      (return-from %get-fn-arglist result)))
  ;; 3. Try function-lambda-expression (parses from source/debug info)
  (multiple-value-bind (expr err)
      (ignore-errors (function-lambda-expression fn))
    (declare (ignore err))
    (when (and expr (consp expr) (eq (first expr) 'lambda) (consp (second expr)))
      (return-from %get-fn-arglist (second expr))))
  nil)

(defun %print-fn-entry (sym)
  (let* ((fn (or (macro-function sym) (symbol-function sym)))
         (args (%get-fn-arglist fn))
         (docstr (documentation sym 'function)))
    (format t "~%>>  ~(~A~)" (symbol-name sym))
    (if args
        (format t " (~{~(~A~)~^ ~})" args)
        (format t " [no-args]"))
    (terpri)
    (when (and docstr (not (string= docstr "")))
      (with-input-from-string (s docstr)
        (loop for line = (read-line s nil nil)
              while line
              do (format t "    ~A~%" line))))
    (terpri)
    (terpri)))

(defun %print-category-detail (keyword &key (stream t) (index *category-fn-index*)
                                         (packages t))
  (unless (find-package :sb-introspect)
    (format stream "~&sb-introspect not available — cannot look up categories~%")
    (return-from %print-category-detail nil))
  (let ((matches (%find-categories keyword index)))
    (cond
      ((null matches)
       (format stream "~&No category found matching ~S~%" keyword)
       nil)
      ((= 1 (length matches))
       (destructuring-bind (display stem fns) (first matches)
         (declare (ignore stem))
         (format stream "~&── ~A ────────────────────────────────────────~2%" display)
         (dolist (sym (sort fns (lambda (a b)
                                  (string-lessp (symbol-name a) (symbol-name b)))))
           (%print-fn-entry sym))
         t))
      (t
       (format stream "~&── Matching categories ──────────────────────────~2%")
       (dolist (match matches)
         (destructuring-bind (display stem fns) match
           (declare (ignore stem fns))
           (format stream "  ~A~30T~2D ~:Pfunction~%" display (length fns))))
       (format stream "~%  Drill in: (browse :<category>)~%")
       t))))


;; ---
;; browse
;; ---

(defun %browse-tree (&key (packages t))
  (%ensure-category-index :packages packages)
  (%print-category-tree))

(defun %browse-category (keyword &key (packages t))
  (%ensure-category-index :packages packages)
  (%print-category-detail keyword))

(defun %browse-substring-search (pattern &key (packages nil packages-supplied-p)
                                            (case-insensitive t))
  (let* ((pattern-str (etypecase pattern
                         (string pattern)
                         (symbol (symbol-name pattern))))
         (raw-packages
           (cond
             ((null packages) (list :clotcad :cl-occt))
             ((eq packages t) t)
             (t packages)))
         (target-packages
           (if (eq raw-packages t)
               (list-all-packages)
               (mapcar #'find-package (%coerce-packages raw-packages))))
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
    (when matches
      (setf matches (sort matches (lambda (a b)
                                    (let ((pkg-a (package-name (symbol-package (car a))))
                                          (pkg-b (package-name (symbol-package (car b))))
                                          (name-a (symbol-name (car a)))
                                          (name-b (symbol-name (car b))))
                                      (if (string= pkg-a pkg-b)
                                          (string-lessp name-a name-b)
                                          (string-lessp pkg-a pkg-b)))))))
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

(defun browse-impl (pattern &key (packages nil packages-supplied-p) (case-insensitive t))
  (%browse-substring-search pattern
                              :packages (when packages-supplied-p
                                          (%coerce-packages packages))
                              :case-insensitive case-insensitive))

(defmacro browse (&optional (pattern nil pattern-supplied-p)
                    &key (packages nil packages-supplied-p) (case-insensitive t))
  (cond
    ((not pattern-supplied-p)
     (if packages-supplied-p
         `(%browse-tree :packages ',packages)
         `(%browse-tree)))
    ((keywordp pattern)
     (if packages-supplied-p
         `(%browse-category ',pattern :packages ',packages)
         `(%browse-category ',pattern)))
    (t
     (let ((quoted-pattern
             (cond
               ((stringp pattern) pattern)
               ((and (consp pattern) (member (car pattern) '(function quote)))
                pattern)
               (t `',pattern))))
       `(browse-impl ,quoted-pattern
                      ,@(when packages-supplied-p `(:packages ,packages))
                      :case-insensitive ,case-insensitive)))))


