(in-package :clotcad.impl)

(defmacro -> (value &rest forms)
  (reduce (lambda (acc form)
            (if (listp form)
                `(,(car form) ,acc ,@(cdr form))
                `(,form ,acc)))
          forms
          :initial-value value))

(defmacro ->> (value &rest forms)
  (reduce (lambda (acc form)
            (if (listp form)
                `(,(car form) ,@(cdr form) ,acc)
                `(,form ,acc)))
          forms
          :initial-value value))

(defmacro as-> (value var &rest forms)
  (reduce (lambda (acc form)
            `(let ((,var ,acc))
               ,form))
          forms
          :initial-value value))
