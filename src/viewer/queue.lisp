(in-package :cl-occt-viewer)

(defvar *viewer* nil
  "Handle to the C viewer instance.")

(defvar *viewer-running* nil
  "Flag to signal viewer thread to stop.")

(defvar *viewer-queue* nil
  "Queue of messages for the viewer thread.")

(defvar *queue-lock* (sb-thread:make-mutex)
  "Mutex protecting the viewer queue.")

(defvar *displayed-models* (make-hash-table :test 'equal)
  "Map model name (string) → shape object currently displayed.")

(defun queue-push (type name &optional shape)
  (sb-thread:with-mutex (*queue-lock*)
    (push (list type name shape) *viewer-queue*))
  (when *viewer*
    (%viewer-post-event *viewer*)))

(defun drain-queue (&optional vwr)
  (let ((items '())
        (viewer (or vwr *viewer*)))
    (sb-thread:with-mutex (*queue-lock*)
      (rotatef items *viewer-queue*))
    (dolist (msg items)
      (destructuring-bind (type name &optional shape) msg
        (case type
          (:display
           (when (and shape viewer)
             (%viewer-put-shape viewer (cl-occt::%ptr shape) name)
              (setf (gethash name *displayed-models*) shape)))
          (:update
           (when (and shape viewer)
             (%viewer-put-shape viewer (cl-occt::%ptr shape) name)))
          (:remove
           (when viewer
             (%viewer-remove-shape viewer name))
           (remhash name *displayed-models*))
          (:clear
           (when viewer
             (%viewer-clear viewer))
           (clrhash *displayed-models*)))))))

(defun display (name shape)
  (let ((sname (string name)))
    (setf (gethash sname *displayed-models*) shape)
    (queue-push :display sname shape)))

(defun undisplay (name)
  (let ((sname (string name)))
    (remhash sname *displayed-models*)
    (queue-push :remove sname)))

(defun clear-all ()
  (clrhash *displayed-models*)
  (queue-push :clear nil))

;; --- DAG bridge: auto-display models after propagation ---
(defun viewer-refresh ()
  (loop for name being the hash-keys of cl-occt.impl:*model-registry*
        using (hash-value m)
        when (gethash (string name) *displayed-models*)
        do (let ((cached (cl-occt.impl:model-cached-shape m)))
             (if cached
                 (queue-push :update (string name) cached)
                 (queue-push :remove (string name))))))

(let ((original (symbol-function 'cl-occt.impl:propagate-changes)))
  (setf (symbol-function 'cl-occt.impl:propagate-changes)
        (lambda ()
          (funcall original)
          (viewer-refresh))))
