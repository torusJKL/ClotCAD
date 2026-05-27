(defpackage :clotcad.impl
  (:use :cl :cffi)
  (:import-from :cl-occt :shape :shape-p)
  (:export
   ;; Lifecycle
   :%viewer-create
   :%viewer-destroy
   :%viewer-show
   :%viewer-set-window-state
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
   :%viewer-set-viewcube-font-height
   :%viewer-get-device-pixel-ratio
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
   :%viewer-set-trihedron-font-size
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
   ;; Dialogs
   :%viewer-show-message
   ;; Exported Lisp variables and functions
   :*viewer*
   :*viewer-queue*
   :*queue-lock*
   :*displayed-models*
   :*grid-visible*
   :*axis-visible*
   :start-viewer
   :stop-viewer
   :quit-clotcad
   :start-slynk
   :start-alive
   :wait-forever
   :bootstrap
   :sync-viewer
   :display
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
   :*repl-accumulator*
   ;; Model layer internals
   :model
   :make-model
   :model-p
   :model-name
   :model-fn
   :model-param-keys
   :model-model-deps
   :model-dependents
   :model-dirty
   :model-cached-shape
   :model-last-param-hash
   :model-color-val
   :model-display-name-val
   :model-layer-val
   :normalize-name
   :*model-registry*
   :*params*
   :*after-propagation-hook*
   :*local-params*
   :register-model
   :find-model
   :unregister-model
    :dirty-model!
    :topological-sort
    :evaluate-model
    :propagate-changes
     :propagate-named-subshapes
     :model-named-subshapes
     :model-named-subshape-cache
     ;; Threading macros
     :->
     :->>
     :as->))

(defpackage :clotcad
  (:use :cl :clotcad.impl)
  (:shadow :apropos)
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
   :quit-clotcad
   :start-slynk
   :start-alive
   :wait-forever
   :bootstrap
   :display
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
   :set-viewcube-font-height
   :set-trihedron-font-size
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
   ;; Introspection
   :doc
   :apropos
   ;; Lisp import/export
   :cancel-import
   :replay-speed
   :result-export
   :export-repl-history
   :log-remote-eval
   ;; Parametric DSL
   :defmodel
   :param
   :with-params
   :model-ref
   :model-color
   :model-display-name
   :model-layer
   :set-param!
   :set-params!
   :*params*
   :*model-registry*
   :help
   :write-dag-models-to-step
    :read-step-into-dag
     ;; Coordinate frames
     :frame
     :frame-origin
     :frame-x-axis
     :frame-y-axis
     :frame-z-axis
     :make-frame-on-face
     :make-frame-on-plane
     :frame-to-location
     ;; Subshape queries
     :query-shape
    :face-p
    :edge-p
    :vertex-p
    :normal-along
    :surface-type
    :curve-type
    :longer-than
    :shorter-than
    :larger-than
    :smaller-than
    :max-by
    :min-by
    :x-center
    :y-center
    :z-center
    :edge-along
    :radius-around
    :top-face
    :bottom-face
    :longest-edge
    :largest-face
    :shortest-edge
     :smallest-face
     ;; Named subshapes
     :name-subshape
     :face-ref
     :edge-ref
     :vertex-ref
     :list-named-subshapes
     :remove-named-subshape
     ;; Threading macros
     :->
     :->>
     :as->))

(defpackage :clotcad-user
  (:use :cl :cl-occt :clotcad)
  (:shadowing-import-from :clotcad
   :cut :fuse :common :section :translate :rotate
   :make-prism :make-revol :make-compound :make-part
   :write-step :write-stl
   :apropos
   :surface-type :curve-type
   :longer-than :shorter-than :larger-than :smaller-than)
  (:nicknames :cad-user :occt-user))
