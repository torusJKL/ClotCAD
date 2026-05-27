(in-package :clotcad.impl)

(defstruct model
  (name nil :type string)
  (fn nil :type (or null function))
  (param-keys nil :type list)
  (model-deps nil :type list)
  (dependents nil :type list)
  (dirty t :type boolean)
  (cached-shape nil)
  (last-param-hash nil :type (or null fixnum))
  (color-val nil :type (or null list))
  (display-name-val nil :type (or null string))
  (layer-val nil :type (or null string))
  (named-subshapes nil :type list)
  (named-subshape-cache nil :type list))

(defun normalize-name (name)
  (string-downcase (string name)))

(defvar *model-registry* (make-hash-table :test 'equal)
  "Map model name (string) → model struct.")

(defun register-model (name model)
  (setf (gethash (normalize-name name) *model-registry*) model))

(defun find-model (name)
  (gethash (normalize-name name) *model-registry*))

(defun unregister-model (name)
  (remhash (normalize-name name) *model-registry*))
