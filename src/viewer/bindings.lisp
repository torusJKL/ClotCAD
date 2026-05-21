(in-package :cl-occt-viewer.impl)

(define-foreign-library libocctviewer
  (:unix (:or "libocctviewer.so"
              (merge-pathnames "lib/libocctviewer.so"
                               (asdf:system-source-directory :cl-occt-viewer))))
  (t (:default "libocctviewer")))

(use-foreign-library libocctviewer)

;; --- Lifecycle ---

(defcfun (%viewer-create "viewer_create") :pointer
  (title :string) (width :int) (height :int))

(defcfun (%viewer-destroy "viewer_destroy") :void
  (vwr :pointer))

(defcfun (%viewer-show "viewer_show") :void
  (vwr :pointer))

(defcfun (%viewer-run "viewer_run") :void
  (vwr :pointer))

(defcfun (%viewer-quit "viewer_quit") :void
  (vwr :pointer))

(defcfun (%viewer-is-running "viewer_is_running") :int
  (vwr :pointer))

;; --- Inter-thread wake ---

(defcfun (%viewer-post-event "viewer_post_event") :void
  (vwr :pointer))

(defcfun (%viewer-redraw "viewer_redraw") :void
  (vwr :pointer))

;; --- Shape sync ---

(cffi:defcstruct shape-sync-item
  (:name :pointer)
  (:shape-ptr :pointer)
  (:checked :int)
  (:show-in-tree :int)
  (:shape-changed :int))

(defcfun (%viewer-sync-shapes "viewer_sync_shapes") :void
  (vwr :pointer) (items :pointer) (count :int))

(defcfun (%viewer-fit-all "viewer_fit_all") :void
  (vwr :pointer))

;; --- Callbacks ---

(defcfun (%viewer-set-eval-callback "viewer_set_eval_callback") :void
  (vwr :pointer) (fn :pointer))

(defcfun (%viewer-set-file-op-callback "viewer_set_file_op_callback") :void
  (vwr :pointer) (fn :pointer))

(defcfun (%viewer-set-drain-callback "viewer_set_drain_callback") :void
  (vwr :pointer) (fn :pointer))

;; --- REPL ---

(defcfun (%viewer-append-repl-output "viewer_append_repl_output") :void
  (vwr :pointer) (text :string))

;; --- Scene tree ---

(defcfun (%viewer-set-shape-visible "viewer_set_shape_visible") :void
  (vwr :pointer) (name :string) (visible :int))

;; --- Grid ---

(defcfun (%viewer-show-grid "viewer_show_grid") :void
  (vwr :pointer) (show :int))

(defcfun (%viewer-is-grid-visible "viewer_is_grid_visible") :int
  (vwr :pointer))

;; --- Axis ---

(defcfun (%viewer-show-axis "viewer_show_axis") :void
  (vwr :pointer) (show :int))

(defcfun (%viewer-is-axis-visible "viewer_is_axis_visible") :int
  (vwr :pointer))

;; --- Dock panels ---

(defcfun (%viewer-show-dock "viewer_show_dock") :void
  (vwr :pointer) (dock-name :string) (show :int))

;; --- Quality ---

(defcfun (%viewer-set-antialiasing "viewer_set_antialiasing") :void
  (vwr :pointer) (enable :int))

;; --- Theme ---

(defcfun (%viewer-set-stylesheet "viewer_set_stylesheet") :void
  (vwr :pointer) (qss :string))

(defcfun (%viewer-color-scheme "viewer_color_scheme") :int
  (vwr :pointer))

(defcfun (%viewer-set-color-scheme-callback "viewer_set_color_scheme_callback") :void
  (vwr :pointer) (fn :pointer))

(defcfun (%viewer-get-view "viewer_get_view") :pointer
  (vwr :pointer))

(defcfun (%viewer-get-trihedron "viewer_get_trihedron") :pointer
  (vwr :pointer))

(defcfun (%viewer-set-placeholder-color "viewer_set_placeholder_color") :void
  (vwr :pointer) (r :int) (g :int) (b :int))

(defcfun (%viewer-set-status-text "viewer_set_status_text") :void
  (vwr :pointer) (text :string))

(defcfun (%viewer-set-visibility-callback "viewer_set_visibility_callback") :void
  (vwr :pointer) (fn :pointer))

;; --- Selection ---

(defcfun (%viewer-get-context "viewer_get_context") :pointer
  (vwr :pointer))

(defcfun (%viewer-get-ais-object "viewer_get_ais_object") :pointer
  (vwr :pointer) (name :string))

(defcfun (%viewer-set-selection-callback "viewer_set_selection_callback") :void
  (vwr :pointer) (fn :pointer))

(defcfun (%viewer-set-tree-selection-callback "viewer_set_tree_selection_callback") :void
  (vwr :pointer) (fn :pointer))

(defcfun (%viewer-set-mouse-selection-scheme "viewer_set_mouse_selection_scheme") :void
  (vwr :pointer) (key :int) (scheme :int))

(defcfun (%viewer-sync-tree-selection "viewer_sync_tree_selection") :void
  (vwr :pointer))

(defcfun (%viewer-select-names "viewer_select_names") :void
  (vwr :pointer) (names :pointer) (count :int))

(defcfun (%viewer-is-shape-selected "viewer_is_shape_selected") :int
  (vwr :pointer) (name :string))
