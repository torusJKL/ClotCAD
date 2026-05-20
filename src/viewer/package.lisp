(defpackage :cl-occt-viewer.impl
  (:use :cl :cffi)
  (:import-from :cl-occt :shape :shape-p)
  (:export
   ;; Lifecycle
   :%viewer-create
   :%viewer-destroy
   :%viewer-show
   :%viewer-run
   :%viewer-quit
   :%viewer-is-running
   ;; Inter-thread wake
   :%viewer-post-event
   :%viewer-redraw
   ;; Shapes
   :%viewer-put-shape
   :%viewer-remove-shape
   :%viewer-clear
   :%viewer-fit-all
   ;; Callbacks
   :%viewer-set-eval-callback
   :%viewer-set-file-op-callback
   :%viewer-set-drain-callback
   ;; REPL
   :%viewer-append-repl-output
   ;; Scene tree
   :%viewer-get-shape-count
   :%viewer-get-shape-name
   :%viewer-set-shape-visible
   :%viewer-is-shape-visible
   :%viewer-notify-shape-change
   ;; Grid
   :%viewer-show-grid
   :%viewer-is-grid-visible
   ;; Axis
   :%viewer-show-axis
   :%viewer-is-axis-visible
   ;; Dock panels
   :%viewer-show-dock
   ;; Quality
   :%viewer-set-antialiasing
   ;; Exported Lisp variables and functions
   :*viewer*
   :*viewer-queue*
   :*queue-lock*
   :*displayed-models*
   :*grid-visible*
   :*axis-visible*
   :start-viewer
   :stop-viewer
   :display
   :undisplay
   :clear-all
   :register-viewer-callbacks
   :drain-queue
   :show-grid
   :show-axis
   :toggle-grid
   :toggle-axis
   :set-antialiasing
   :fit-all
   :run-tests
   :*repl-eof-sentinel*
   :*repl-accumulator*))

(defpackage :cl-occt-viewer
  (:use :cl :cl-occt-viewer.impl)
  (:import-from :cl-occt :shape :shape-p)
  (:export
   :start-viewer
   :stop-viewer
   :display
   :undisplay
   :clear-all
   :show-grid
   :show-axis
   :toggle-grid
   :toggle-axis
   :show-repl
   :show-scene-tree
   :toggle-repl
   :toggle-scene-tree
   :set-antialiasing
   :fit-all
   :run-tests))
