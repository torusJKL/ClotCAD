(in-package :cl-occt-viewer)

(defvar *repl-accumulator* ""
  "Accumulates incomplete REPL input for multiline support.")

(defvar *repl-eof-sentinel* (gensym "REPL-EOF")
  "Sentinel value for read-from-string eof-value.")

(cffi:defcallback eval-string :void ((code :string) (result :pointer) (maxlen :int))
  (handler-case
      (let* ((full-code (if (string= *repl-accumulator* "")
                            code
                            (concatenate 'string *repl-accumulator* code))))
        (multiple-value-bind (form pos)
            (read-from-string full-code nil *repl-eof-sentinel*)
          (if (eq form *repl-eof-sentinel*)
              (progn
                (setf *repl-accumulator* full-code)
                (cffi:foreign-funcall "snprintf" :pointer result :int maxlen :string "" :int 0 :void))
              (let ((values (multiple-value-list (eval form))))
                (setf *repl-accumulator* "")
                (let ((output (with-output-to-string (s)
                                (dolist (v values)
                                  (format s "~S~%" v)))))
                  (cffi:foreign-funcall "snprintf" :pointer result :int maxlen :string output :int (min (length output) (1- maxlen)) :void))))))
    (error (e)
      (setf *repl-accumulator* "")
      (cffi:foreign-funcall "snprintf" :pointer result :int maxlen :string (format nil "Error: ~A~%" e) :int 0 :void))))

(defun get-displayed-names ()
  (loop for k being the hash-keys of *displayed-models* collect k))

(defun first-displayed-shape ()
  (let ((names (get-displayed-names)))
    (when names
      (let ((name (first names)))
        (values (gethash name *displayed-models*) name)))))

(cffi:defcallback handle-file-op :void ((path :string) (op :int))
  (handler-case
      (case op
        (0  ;; import STEP
         (let ((shape (cl-occt:read-step path)))
           (when shape
             (let ((name (format nil "imported-~A" (pathname-name path))))
               (display name shape)
               (%viewer-fit-all *viewer*)))))
        (1  ;; export STEP
         (multiple-value-bind (shape name) (first-displayed-shape)
           (declare (ignore name))
           (when shape
             (cl-occt:write-step shape path))))
        (2  ;; export STL
         (multiple-value-bind (shape name) (first-displayed-shape)
           (declare (ignore name))
           (when shape
             (cl-occt:write-stl shape path :deflection 0.1))))
        (3  ;; import STL
         (let ((shape (cl-occt:read-stl path)))
           (when shape
             (let ((name (format nil "imported-~A" (pathname-name path))))
               (display name shape)
               (%viewer-fit-all *viewer*))))))
    (error (e)
      (format *error-output* "~&File operation error: ~A~%" e))))

(cffi:defcallback drain-queue-callback :void ()
  (drain-queue *viewer*))

(defun register-viewer-callbacks (vwr)
  (setf *viewer* vwr)
  (cl-occt-viewer.impl:%viewer-set-eval-callback vwr (cffi:callback eval-string))
  (cl-occt-viewer.impl:%viewer-set-file-op-callback vwr (cffi:callback handle-file-op))
  (cl-occt-viewer.impl:%viewer-set-drain-callback vwr (cffi:callback drain-queue-callback)))
