(in-package :clotcad)

(defun %assoc-delete-all (item alist &key (test #'eql))
  (loop for entry in alist
        unless (funcall test item (car entry))
        collect entry))

(defun %re-evaluate-named-subshape (model name)
  (let* ((sname (string model))
         (m (clotcad.impl:find-model sname)))
    (unless m
      (error "~S does not name a known model" model))
    (let* ((key (intern (string-upcase (string name)) :keyword))
           (entry (assoc key (clotcad.impl:model-named-subshapes m) :test #'eq)))
      (unless entry
        (error "Named subshape ~S not found on ~S" name model))
      (let ((cached (assoc key (clotcad.impl:model-named-subshape-cache m) :test #'eq)))
        (when cached
          (return-from %re-evaluate-named-subshape (cdr cached))))
      (let* ((plist (cdr entry))
             (where (getf plist :where))
             (cs (getf plist :coordinate-system :local))
             (results (query-shape (clotcad.impl:model-cached-shape m)
                                   :where where
                                   :coordinate-system cs)))
        (setf (clotcad.impl:model-named-subshape-cache m)
              (acons key results (clotcad.impl:model-named-subshape-cache m)))
        results))))

(defun name-subshape (model name &rest query-args
                      &key (where nil) (coordinate-system :local))
  "Register a named subshape query on a model.

  Associates NAME with a `query-shape` specification that is
  re-evaluated each time the subshape is accessed. The query
  survives shape recomputation (e.g. after `defmodel` parameter changes).

  - **model** string, keyword, or symbol identifying the model
  - **name** keyword or symbol naming the subshape (without model prefix)
  - **where** a list of predicate closures (same as `query-shape :where`)
  - **coordinate-system** `:local` or `:global` (default `:local`)

  **Returns:** the NAME keyword.

  **Example:**

      (def :my-box (make-box 10 20 30))
      (name-subshape :my-box :top-face
        :where (list (face-p) (normal-along 0 0 1) (max-by #'z-center)))

  **See also:** `face-ref`, `edge-ref`, `vertex-ref`, `list-named-subshapes`,
  `remove-named-subshape`"
  (declare (ignore where coordinate-system))
  (let* ((sname (string model))
         (m (clotcad.impl:find-model sname)))
    (unless m
      (error "~S does not name a known model" model))
    (let* ((key (intern (string-upcase (string name)) :keyword))
           (existing (assoc key (clotcad.impl:model-named-subshapes m) :test #'eq))
           (plist (copy-list query-args)))
      ;; Named subshapes are invisible by default; user must call SHOW to make them visible
      (setf (getf plist :visible) nil)
      (if existing
          (setf (cdr existing) plist)
          (setf (clotcad.impl:model-named-subshapes m)
                (acons key plist (clotcad.impl:model-named-subshapes m))))
      (setf (clotcad.impl:model-named-subshape-cache m)
            (%assoc-delete-all key (clotcad.impl:model-named-subshape-cache m)))
      (when (gethash sname *displayed-models*)
        (queue-push :sync))
      name)))

(defun face-ref (model name)
  "Resolve a named subshape and return the matching face.

  Re-evaluates the stored query on the model's current shape and
  returns the first face result. Signals an error if the name is
  not registered or if the resolved subshape is not a face.

  - **model** string, keyword, or symbol identifying the model
  - **name** keyword or symbol naming the subshape (without model prefix)

  **Returns:** a single `face` shape.

  **Example:**

      (def :my-box (make-box 10 20 30))
      (name-subshape :my-box :top-face
        :where (list (face-p) (normal-along 0 0 1) (max-by #'z-center)))
      (face-ref :my-box :top-face)  ;; => #<FACE ...>

  **See also:** `edge-ref`, `vertex-ref`, `name-subshape`"
  (let* ((results (%re-evaluate-named-subshape model name))
         (faces (remove-if-not
                 (lambda (s) (eq (cl-occt:shape-type s) :face))
                 results)))
    (if faces
        (first faces)
        (error "Named subshape ~S on ~S is not a face" name model))))

(defun edge-ref (model name)
  "Resolve a named subshape and return the matching edge.

  Re-evaluates the stored query on the model's current shape and
  returns the first edge result. Signals an error if the name is
  not registered or if the resolved subshape is not an edge.

  - **model** string, keyword, or symbol identifying the model
  - **name** keyword or symbol naming the subshape (without model prefix)

  **Returns:** a single `edge` shape.

  **Example:**

      (def :my-box (make-box 10 20 30))
      (name-subshape :my-box :longest-edge
        :where (list (edge-p) (max-by #'cl-occt:edge-length)))
      (edge-ref :my-box :longest-edge)  ;; => #<EDGE ...>

  **See also:** `face-ref`, `vertex-ref`, `name-subshape`"
  (let* ((results (%re-evaluate-named-subshape model name))
         (edges (remove-if-not
                 (lambda (s) (eq (cl-occt:shape-type s) :edge))
                 results)))
    (if edges
        (first edges)
        (error "Named subshape ~S on ~S is not an edge" name model))))

(defun vertex-ref (model name)
  "Resolve a named subshape and return the matching vertex.

  Re-evaluates the stored query on the model's current shape and
  returns the first vertex result. Signals an error if the name is
  not registered or if the resolved subshape is not a vertex.

  - **model** string, keyword, or symbol identifying the model
  - **name** keyword or symbol naming the subshape (without model prefix)

  **Returns:** a single `vertex` shape.

  **Example:**

      (def :my-box (make-box 10 20 30))
      (name-subshape :my-box :origin-corner
        :where (list (vertex-p) (x-center 0) (y-center 0) (z-center 0)))
      (vertex-ref :my-box :origin-corner)  ;; => #<VERTEX ...>

  **See also:** `face-ref`, `edge-ref`, `name-subshape`"
  (let* ((results (%re-evaluate-named-subshape model name))
         (vertices (remove-if-not
                    (lambda (s) (eq (cl-occt:shape-type s) :vertex))
                    results)))
    (if vertices
        (first vertices)
        (error "Named subshape ~S on ~S is not a vertex" name model))))

(defun %parse-compound-symbol (symbol)
  (let ((str (string symbol)))
    (let ((pos (position #\/ str)))
      (unless pos
        (return-from %parse-compound-symbol nil))
      (values (intern (string-upcase (subseq str 0 pos)) :keyword)
              (intern (string-upcase (subseq str (1+ pos))) :keyword)))))

(defun %resolve-compound-symbol (symbol)
  (multiple-value-bind (model-name subshape-name)
      (%parse-compound-symbol symbol)
    (unless model-name
      (return-from %resolve-compound-symbol nil))
    (let ((m (clotcad.impl:find-model model-name)))
      (unless m
        (error "~S does not name a known model" model-name))
      (let ((cached (clotcad.impl:model-cached-shape m)))
        (unless cached
          (error "Model ~S has no cached shape" model-name))
        (let ((results (%re-evaluate-named-subshape model-name subshape-name)))
          (first results))))))

(defun list-named-subshapes (model)
  "Return a list of registered subshape names on a model.

  - **model** string, keyword, or symbol identifying the model

  **Returns:** a list of keyword names.

  **Example:**

      (def :my-box (make-box 10 20 30))
      (name-subshape :my-box :top-face
        :where (list (face-p) (normal-along 0 0 1)))
      (name-subshape :my-box :longest-edge
        :where (list (edge-p) (max-by #'cl-occt:edge-length)))
      (list-named-subshapes :my-box)  ;; => (:TOP-FACE :LONGEST-EDGE)

  **See also:** `remove-named-subshape`, `name-subshape`"
  (let* ((sname (string model))
         (m (clotcad.impl:find-model sname)))
    (unless m
      (error "~S does not name a known model" model))
    (mapcar #'car (clotcad.impl:model-named-subshapes m))))

(defun remove-named-subshape (model name)
  "Remove a previously registered named subshape.

  Signals an error if the name is not found on the model.

  - **model** string, keyword, or symbol identifying the model
  - **name** keyword or symbol naming the subshape to remove

  **Returns:** the NAME keyword.

  **Example:**

      (name-subshape :my-box :top-face
        :where (list (face-p) (normal-along 0 0 1)))
      (remove-named-subshape :my-box :top-face)
      (face-ref :my-box :top-face)  ;; signals error

  **See also:** `list-named-subshapes`, `name-subshape`"
  (let* ((sname (string model))
         (m (clotcad.impl:find-model sname)))
    (unless m
      (error "~S does not name a known model" model))
    (let* ((key (intern (string-upcase (string name)) :keyword))
           (entry (assoc key (clotcad.impl:model-named-subshapes m) :test #'eq)))
      (unless entry
        (error "Named subshape ~S not found on ~S" name model))
      (setf (clotcad.impl:model-named-subshapes m)
            (remove entry (clotcad.impl:model-named-subshapes m)))
      (setf (clotcad.impl:model-named-subshape-cache m)
            (%assoc-delete-all key (clotcad.impl:model-named-subshape-cache m)))
      (when (gethash sname *displayed-models*)
        (queue-push :sync))
      name)))
