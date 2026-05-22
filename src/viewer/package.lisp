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
    :%viewer-post-event-delayed
    :%viewer-redraw
    ;; Shapes
    :%viewer-sync-shapes
    :%viewer-fit-all
    :shape-sync-item
   ;; Callbacks
   :%viewer-set-eval-callback
   :%viewer-set-file-op-callback
   :%viewer-set-drain-callback
    ;; REPL
    :%viewer-append-repl-output
    :%viewer-set-repl-history-modifier
    :%viewer-set-repl-submit-modifier
     ;; Scene tree
     :%viewer-set-shape-visible
    ;; Grid
    :%viewer-show-grid
    :%viewer-is-grid-visible
    ;; Axis
    :%viewer-show-axis
    :%viewer-is-axis-visible
    ;; ViewCube
    :%viewer-show-viewcube
    :%viewer-is-viewcube-visible
    :%viewer-set-view
    :%viewer-get-view-orientation
    :%viewer-set-viewcube-callback
    :%viewer-set-viewcube-color
    :%viewer-set-viewcube-text-color
    :%viewer-set-viewcube-inner-color
    :%viewer-set-viewcube-transparency
    :%viewer-set-viewcube-size
    :%viewer-set-viewcube-axis-color
    :%viewer-set-viewcube-draw-axes
    :%viewer-get-viewcube-draw-axes
    :%viewer-set-viewcube-hilight-color
   ;; Dock panels
   :%viewer-show-dock
    ;; Quality
    :%viewer-set-antialiasing
     ;; Theme
     :%viewer-set-stylesheet
     :%viewer-set-icon-palette
     :%viewer-color-scheme
    :%viewer-set-color-scheme-callback
    :%viewer-get-view
     :%viewer-get-trihedron
     :%viewer-set-trihedron-text-color
     :%viewer-set-placeholder-color
    :%viewer-set-status-text
:%viewer-set-import-status
     :%viewer-set-visibility-callback
     ;; Selection
     :%viewer-get-context
     :%viewer-get-ais-object
     :%viewer-set-selection-callback
     :%viewer-set-tree-selection-callback
     :%viewer-set-mouse-selection-scheme
     :%viewer-sync-tree-selection
     :%viewer-select-names
     :%viewer-is-shape-selected
     ;; Exported Lisp variables and functions
   :*viewer*
   :*viewer-queue*
   :*queue-lock*
   :*displayed-models*
   :*grid-visible*
   :*axis-visible*
   :start-viewer
   :stop-viewer
    :sync-viewer
    :display
    :undisplay
    :clear-all
    :register-viewer-callbacks
    :drain-queue
     :show-grid
     :show-axis
     :toggle-grid
     :toggle-axis
     :set-view-aa
    :fit-view
    :run-tests
   :*repl-eof-sentinel*
   :*repl-accumulator*))

(defpackage :cl-occt-viewer
  (:use :cl :cl-occt-viewer.impl)
  (:import-from :cl-occt :shape :shape-p
               :ais-clear-selected :ais-set-selected
               :ais-add-or-remove-selected
               :ais-hilight-selected :ais-is-selected
               :*selection-scheme-map*)
   (:export
    :*show-defs-in-tree*
    :resolve-shape
    :def
    :show
    :hide
    :toggle
    :show-defs
    :toggle-defs
    :cut
    :fuse
    :common
    :section
    :translate
    :rotate
    :make-prism
    :make-revol
    :make-compound
    :make-part
    :write-step
    :write-stl
    :start-viewer
    :stop-viewer
    :display
    :undisplay
    :clear-all
    :show-grid
    :show-axis
    :toggle-grid
     :toggle-axis
     :show-viewcube
     :toggle-viewcube
     :show-viewcube-axes
     :toggle-viewcube-axes
     :set-view
     :current-view
     :show-repl
    :show-scene-tree
    :toggle-repl
    :toggle-scene-tree
     :set-view-aa
     :fit-view
      :run-tests
      :set-repl-history-key
      :set-repl-submit-key
      :apply-theme
     :set-accent
     :theme-dark
     :theme-light
     :theme-auto
     :set-font-size
        :*theme-mode*
        :*accent-color*
        :*font-size*
        :*current-view*
        :*viewcube-visible*
        ;; Selection
        :*selected*
        :select
        :deselect
        :clear-selection
        :selected-shapes
        :apply-selection-schemes
        ;; Lisp import/export
        :cancel-import
        :replay-speed
        :result-export
        :export-repl-history))

(defpackage :cl-occt-user
  (:use :cl :cl-occt :cl-occt-viewer)
  (:shadowing-import-from :cl-occt-viewer
   :cut :fuse :common :section :translate :rotate
   :make-prism :make-revol :make-compound :make-part
   :write-step :write-stl)
  (:nicknames :cad-user :occt-user))
