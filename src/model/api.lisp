(in-package :clotcad)

;; --- Shape resolution ---

(defun resolve-shape (designator)
  (etypecase designator
    (cl-occt:shape designator)
    (string (let ((m (clotcad.impl:find-model designator)))
              (if m
                  (clotcad.impl:model-cached-shape m)
                  (error "~S does not name a known shape" designator))))
    (symbol (resolve-shape (string designator)))))

;; --- Model metadata accessors ---

(defun model-color (name)
  (let ((m (clotcad.impl:find-model name)))
    (if m
        (clotcad.impl:model-color-val m)
        (error "Model ~S not found" name))))

(defun model-display-name (name)
  (let ((m (clotcad.impl:find-model name)))
    (if m
        (clotcad.impl:model-display-name-val m)
        (error "Model ~S not found" name))))

(defun model-layer (name)
  (let ((m (clotcad.impl:find-model name)))
    (if m
        (clotcad.impl:model-layer-val m)
        (error "Model ~S not found" name))))

(defun model-ref (name)
  (let ((m (clotcad.impl:find-model name)))
    (if m
        (clotcad.impl:model-cached-shape m)
        (error "Model ~S not found" name))))

;; --- Parameter access ---

(defun param (key)
  (or (and (boundp 'clotcad.impl:*local-params*)
           (getf clotcad.impl:*local-params* key))
      (getf *params* key)
      (error "Param ~S not found" key)))

(defmacro with-params ((&rest bindings) &body body)
  `(let ((clotcad.impl:*local-params* (list ,@(loop for (k v) on bindings by #'cddr
                                       append (list k v)))))
     ,@body))

;; --- defmodel macro ---

(defun %parse-metadata (body)
  (let ((metadata '())
        (rest body))
    (loop while (and rest (consp (car rest))
                     (member (caar rest) '(:color :name :layer)))
          do (push (pop rest) metadata))
    (values (nreverse metadata) rest)))

(defun %collect-model-refs (form)
  (when (consp form)
    (if (and (eq (car form) 'model-ref)
             (symbolp (cadr form)))
        (list (string (cadr form)))
        (append (%collect-model-refs (car form))
                (%collect-model-refs (cdr form))))))

(defun %model-keys-from-params (body)
  (let ((keys '()))
    (labels ((walk (form)
               (when (consp form)
                 (when (and (eq (car form) 'param)
                            (keywordp (cadr form))
                            (not (member (cadr form) keys)))
                   (push (cadr form) keys))
                 (walk (car form))
                 (walk (cdr form)))))
      (walk body))
    (nreverse keys)))

(defmacro defmodel (name (&rest param-keys) &body body)
  (let ((sname (clotcad.impl:normalize-name name)))
    (multiple-value-bind (metadata-clauses real-body) (%parse-metadata body)
      (let* ((all-keys (or param-keys (%model-keys-from-params body)))
             (color-form (cadr (assoc :color metadata-clauses)))
             (name-form (cadr (assoc :name metadata-clauses)))
             (layer-form (cadr (assoc :layer metadata-clauses)))
             (model-deps-string (%collect-model-refs real-body))
             (arg-names (loop for k in all-keys collect (gensym (string k))))
             (key-syms (loop for k in all-keys collect (intern (string k) :keyword))))
        `(progn
           (let ((old (clotcad.impl:find-model ,sname)))
             (when old
               (clotcad.impl:unregister-model ,sname)))
           (let ((m (clotcad.impl:make-model :name ,sname
                                :fn (lambda ()
                                      (values (progn ,@real-body)
                                              ,(when color-form `',color-form)
                                              ,(when name-form `',name-form)
                                              ,(when layer-form `',layer-form)))
                                :param-keys ',all-keys
                                :model-deps ,(mapcar (lambda (d) `(clotcad.impl:normalize-name ',d)) model-deps-string)
                                :dirty t)))
             (clotcad.impl:register-model ,sname m)
             (dolist (dep ',model-deps-string)
               (let ((dm (clotcad.impl:find-model dep)))
                 (when dm
                   (pushnew ,sname (clotcad.impl:model-dependents dm) :test #'string=))))
             (clotcad.impl:propagate-changes))
           (defun ,name (&key ,@(loop for k in key-syms
                                       for g in arg-names
                                       collect `((,k ,g) (clotcad:param ',k))))
             (let ((clotcad.impl:*local-params*
                     (list ,@(loop for k in key-syms
                                   for g in arg-names
                                   append `(,k ,g)))))
               (declare (ignorable clotcad.impl:*local-params*))
               (progn ,@real-body)))
           ',name)))))

;; --- Parameter mutation ---

(defun %mark-models-dirty (key)
  (loop for name being the hash-keys of *model-registry*
        using (hash-value m)
        when (member key (clotcad.impl:model-param-keys m))
        do (clotcad.impl:dirty-model! name)))

(defun set-param! (key value)
  (setf *params*
        (list* key value
               (loop for (k v) on *params* by #'cddr
                     unless (eql k key)
                     append (list k v))))
  (%mark-models-dirty key)
  (clotcad.impl:propagate-changes)
  value)

(defun set-params! (&rest key-values)
  (let ((changed-keys '()))
    (loop for (key value) on key-values by #'cddr
          do (setf *params*
                   (list* key value
                          (loop for (k v) on *params* by #'cddr
                                unless (eql k key)
                                append (list k v))))
          (pushnew key changed-keys))
    (dolist (k changed-keys)
      (%mark-models-dirty k))
    (clotcad.impl:propagate-changes)
    *params*))

;; --- DAG STEP I/O ---

(defun write-dag-models-to-step (path)
  (let ((shapes '()))
    (maphash (lambda (name m)
               (let ((shape (clotcad.impl:model-cached-shape m)))
                 (when shape
                   (push (cl-occt:make-part shape
                                            :name (or (clotcad.impl:model-display-name-val m) name)
                                            :color (clotcad.impl:model-color-val m))
                         shapes))))
             *model-registry*)
    (if shapes
        (cl-occt:write-step-assembly (cl-occt:make-assembly :children (nreverse shapes)) path)
        (error "No shapes in model registry"))))

(defun read-step-into-dag (path)
  (let ((assembly (cl-occt:read-step-assembly path))
        (counter 0))
    (labels ((walk (node)
               (let* ((shape (cl-occt:assembly-shape node))
                      (name (cl-occt:assembly-name node))
                      (color (cl-occt:assembly-color node))
                      (label (clotcad.impl:normalize-name (or name (format nil "imported-~A" (incf counter))))))
                 (unless (clotcad.impl:find-model label)
                   (let ((m (make-model :name label
                                        :cached-shape shape
                                        :color-val color
                                        :display-name-val name)))
                     (clotcad.impl:register-model label m)))
                 (dolist (child (cl-occt:assembly-children node))
                   (walk child)))))
      (walk assembly))))

;; --- Help ---

(defun help ()
  (format t "~&ClotCAD — Common Lisp parametric CAD with 3D viewer~2%")
  (format t "~&3D Primitives:~%")
  (format t "  (make-box dx dy dz)            — rectangular box~%")
  (format t "  (make-cylinder radius height)  — cylinder~%")
  (format t "  (make-sphere radius)           — sphere~%")
  (format t "  (make-cone r1 r2 height)       — cone~%")
  (format t "  (make-torus major minor)       — torus~%")
  (format t "~&Boolean Operations:~%")
  (format t "  (cut shape &rest shapes)       — subtract shapes~%")
  (format t "  (fuse shape &rest shapes)      — union shapes~%")
  (format t "  (common shape &rest shapes)    — intersect shapes~%")
  (format t "  (section shape &rest shapes)   — intersection curves~%")
  (format t "~&Transforms:~%")
  (format t "  (translate shape dx dy dz)     — move shape~%")
  (format t "  (rotate shape ax ay az deg)    — rotate shape~%")
  (format t "~&Viewer:~%")
  (format t "  (display name shape)           — show in 3D scene~%")
  (format t "  (def name shape-form)          — define hidden shape~%")
  (format t "  (show name)                    — make visible~%")
  (format t "  (hide name)                    — make invisible~%")
  (format t "  (clear-all)                    — remove all from scene~%")
  (format t "~&Parametric DSL:~%")
  (format t "  (defmodel name (keys) body)    — define parametric model~%")
  (format t "    body may include :color, :name, :layer metadata clauses~%")
  (format t "  (param key)                    — read parameter value~%")
  (format t "  (model-ref name)               — reference another model's shape~%")
  (format t "  (model-color name)             — get model's color~%")
  (format t "  (model-display-name name)      — get model's display name~%")
  (format t "  (model-layer name)             — get model's layer~%")
  (format t "  (set-param! key value)         — set global parameter~%")
  (format t "  (set-params! &rest kv)         — batch set parameters~%")
  (format t "  (with-params (&rest kv) body)  — local parameter scope~%")
  (format t "~&STEP I/O:~%")
  (format t "  (write-step shape path)        — export single shape~%")
  (format t "  (read-step path)               — import single shape~%")
  (format t "  (write-dag-models-to-step path)— export all DAG models~%")
  (format t "  (read-step-into-dag path)      — import into DAG registry~%")
  (format t "~&STL I/O:~%")
  (format t "  (write-stl shape path)         — export to STL~%")
  (format t "  (read-stl path)                — import from STL~%")
  (format t "~&Introspection:~%")
  (format t "  (help)                         — show this help~%")
  (format t "  *params*                       — global parameter plist~%")
  (format t "  *model-registry*               — registered models~%")
  (values))
