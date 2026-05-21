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
  "Map model name (string) → (shape visible show-in-tree dirty origin).
   shape: the shape object (or nil)
   visible: boolean, whether shape is visible in 3D view
   show-in-tree: boolean, whether shape appears in Scene Tree
   dirty: boolean, whether geometry changed since last sync
   origin: :def or :display")

(defun queue-push (type &optional name shape visible show-in-tree)
  (sb-thread:with-mutex (*queue-lock*)
    (push (list type name shape visible show-in-tree) *viewer-queue*))
  (when *viewer*
    (%viewer-post-event *viewer*)))

(defun sync-viewer (&optional (vwr *viewer*))
  (let* ((count (hash-table-count *displayed-models*))
         (type-size (cffi:foreign-type-size '(:struct shape-sync-item)))
         (items (cffi:foreign-alloc :char :count (* count type-size)))
         (idx 0))
    (maphash (lambda (name entry)
               (destructuring-bind (shape visible show-in-tree dirty origin) entry
                 (declare (ignore origin))
                 (let ((item (cffi:inc-pointer items (* idx type-size))))
                   (setf (cffi:foreign-slot-value item '(:struct shape-sync-item) :name)
                         (cffi:foreign-string-alloc name))
                   (setf (cffi:foreign-slot-value item '(:struct shape-sync-item) :shape-ptr)
                         (if shape (cl-occt::%ptr shape) (cffi:null-pointer)))
                   (setf (cffi:foreign-slot-value item '(:struct shape-sync-item) :checked)
                         (if visible 1 0))
                   (setf (cffi:foreign-slot-value item '(:struct shape-sync-item) :show-in-tree)
                         (if show-in-tree 1 0))
                   (setf (cffi:foreign-slot-value item '(:struct shape-sync-item) :shape-changed)
                         (if dirty 1 0))
                   (incf idx))))
             *displayed-models*)
    (%viewer-sync-shapes vwr items count)
    (loop for i below count
          for item = (cffi:inc-pointer items (* i type-size))
          do (cffi:foreign-string-free
              (cffi:foreign-slot-value item '(:struct shape-sync-item) :name)))
    (cffi:foreign-free items)
    ;; Reset all dirty flags after sync
    (maphash (lambda (name entry)
               (declare (ignore name))
               (setf (fourth entry) nil))
             *displayed-models*)))

(defun drain-queue (&optional vwr)
  (let ((items '())
        (viewer (or vwr *viewer*)))
    (sb-thread:with-mutex (*queue-lock*)
      (rotatef items *viewer-queue*))
    ;; Phase 1: process all messages that update Lisp state
    (dolist (msg items)
      (destructuring-bind (type name &optional shape visible show-in-tree) msg
        (case type
          (:display
           (let ((existing (gethash name *displayed-models*)))
             (setf (gethash name *displayed-models*)
                   (list shape visible show-in-tree t
                         (if existing (fifth existing) :display)))))
          (:remove
           (remhash name *displayed-models*))
          (:clear
           (clrhash *displayed-models*))
          (:sync nil)
          (:sync-selection nil))))
    ;; Sync shapes to C++ (ensures shapes map is populated)
    (when viewer
      (sync-viewer viewer))
    ;; Phase 2: process selection syncs (after shapes are in C++)
    (dolist (msg items)
      (destructuring-bind (type name &optional shape visible show-in-tree) msg
        (declare (ignore name shape visible show-in-tree))
        (when (eql type :sync-selection)
          (sync-selection-to-occt viewer)
          (%viewer-sync-tree-selection viewer))))
    (update-shape-count)))

(defun display (name shape &key (visible t) (show-in-tree t) (origin :display))
  (let ((sname (string name)))
    (setf (gethash sname *displayed-models*)
          (list shape visible show-in-tree t origin))
    (queue-push :display sname shape visible show-in-tree)))

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
        do (let* ((entry (gethash (string name) *displayed-models*))
                  (cached (cl-occt.impl:model-cached-shape m))
                  (old-visible (second entry))
                  (old-show-in-tree (third entry)))
             (if cached
                 (progn
                   (setf (gethash (string name) *displayed-models*)
                         (list cached old-visible old-show-in-tree t :display))
                   (queue-push :display (string name) cached old-visible old-show-in-tree))
                 (queue-push :remove (string name))))))

(let ((original (symbol-function 'cl-occt.impl:propagate-changes)))
  (setf (symbol-function 'cl-occt.impl:propagate-changes)
        (lambda ()
          (funcall original)
          (viewer-refresh))))
