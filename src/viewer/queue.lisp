(in-package :clotcad)

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
    (update-shape-count)
    ;; Phase 3: process Lisp file import tick (no-op when not importing)
    (process-import-tick)))

(defun display (name shape &key (visible t) (show-in-tree t) (origin :display))
  "Display a shape in the 3D viewport with the given name.

  If a model with the same name already exists in the registry,
  it is reused. Otherwise a new model is registered.

  - **name** keyword or string naming the shape
  - **shape** the `shape` object to display
  - **visible** optional boolean, `t` to show immediately (default)
  - **show-in-tree** optional boolean, `t` to appear in Scene Tree (default)
  - **origin** optional keyword, `:display` (default) or `:def`

  **Example:**

      (display :my-box (make-box 10 20 30))
      (display :hidden-sphere (make-sphere 5) :visible nil)"
  (let ((sname (string name)))
    ;; Register a simple model in the DAG registry if not already present
    (unless (find-model sname)
      (register-model sname (make-model :name sname
                                        :cached-shape shape)))
    (setf (gethash sname *displayed-models*)
          (list shape visible show-in-tree t origin))
    (queue-push :display sname shape visible show-in-tree)))

(defun clear-all ()
  "Remove all displayed shapes from the 3D viewport.

  Clears both the display list and the viewer scene.

  **Example:**

      (clear-all)

  **See also:** `display`"
  (clrhash *displayed-models*)
  (queue-push :clear nil))

;; --- DAG bridge: update displayed shapes after propagation ---
(defun viewer-refresh ()
  (maphash (lambda (name m)
             (declare (ignore m))
             (let* ((sname name)
                    (entry (gethash sname *displayed-models*)))
               (when entry
                 (let* ((m2 (find-model sname))
                        (cached (if m2 (model-cached-shape m2) nil))
                        (old-visible (second entry))
                        (old-show-in-tree (third entry)))
                   (if cached
                       (progn
                         (setf (gethash sname *displayed-models*)
                               (list cached old-visible old-show-in-tree t :display))
                         (queue-push :display sname cached old-visible old-show-in-tree))
                       (queue-push :remove sname))))))
           *model-registry*))
