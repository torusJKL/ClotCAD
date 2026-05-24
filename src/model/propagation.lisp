(in-package :clotcad.impl)

(defun dirty-model! (name)
  (let ((sname (string name)))
    (let ((m (find-model sname)))
      (when m
        (setf (model-dirty m) t)
        (dolist (dep (model-dependents m))
          (dirty-model! dep))))))

(defun topological-sort (model-names)
  (let ((sorted '())
        (visited (make-hash-table :test 'equal))
        (visiting (make-hash-table :test 'equal)))
    (labels ((visit (name)
               (let ((sname (string name)))
                 (cond ((gethash sname visited) nil)
                       ((gethash sname visiting)
                        (error "Cycle detected involving ~S" name))
                       (t
                        (setf (gethash sname visiting) t)
                        (let ((m (find-model sname)))
                          (when m
                            (dolist (dep (model-model-deps m))
                              (visit dep))))
                        (remhash sname visiting)
                        (setf (gethash sname visited) t)
                        (push name sorted))))))
      (dolist (n model-names)
        (visit n))
      (nreverse sorted))))

(defun param-hash ()
  (sxhash *params*))

(defun evaluate-model (name)
  (let* ((sname (string name))
         (m (find-model sname))
         (this-hash (param-hash)))
    (unless m
      (return-from evaluate-model nil))
    (let ((fn (model-fn m)))
      (unless fn
        (return-from evaluate-model (model-cached-shape m)))
      (when (and (not (model-dirty m))
                 (eql (model-last-param-hash m) this-hash))
        (return-from evaluate-model (model-cached-shape m)))
      (setf (model-dirty m) nil)
      (setf (model-last-param-hash m) this-hash)
      (multiple-value-bind (shape color-val name-val layer-val)
          (funcall fn)
        (setf (model-cached-shape m) shape)
        (when color-val
          (setf (model-color-val m) color-val))
        (when name-val
          (setf (model-display-name-val m) name-val))
        (when layer-val
          (setf (model-layer-val m) layer-val))
        shape))))

(defun propagate-changes ()
  (let* ((all-names (loop for k being the hash-keys of *model-registry* collect k))
         (dirty-names (remove-if-not (lambda (n)
                                       (let ((m (find-model n)))
                                         (and m (model-dirty m))))
                                     all-names))
         (sorted (ignore-errors (topological-sort dirty-names))))
    (when sorted
      (dolist (name sorted)
        (evaluate-model name)))
    (dolist (fn *after-propagation-hook*)
      (funcall fn))))
