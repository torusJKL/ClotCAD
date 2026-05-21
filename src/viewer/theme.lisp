(in-package :cl-occt-viewer)

;; ======================================================================
;;  Fluent-inspired theme system
;;
;;  Theme state lives in Lisp. The QSS stylesheet is generated from a
;;  template by substituting {{key}} tokens with palette color values.
;;  The result is pushed to C++ via %viewer-set-stylesheet at runtime.
;;
;;  Usage from REPL:
;;    (apply-theme :dark)                    ; dark mode, current accent
;;    (apply-theme :light :accent "#0078d4") ; light mode, blue accent
;;    (set-accent "#FF6600")                 ; orange accent, reapply
;;    (theme-auto)                           ; follow system
;;    (set-font-size "15px")                 ; larger font
;;    (set-font-size "12px")                 ; smaller font
;;    *theme-mode*                           ; query current mode
;;    *accent-color*                         ; query current accent
;;    *font-size*                            ; query current font size
;; ======================================================================

(defvar *theme-mode* :light
  "Current theme mode: :dark, :light, or :auto")

(defvar *accent-color* "#0078d4"
  "Current accent color as a CSS hex string (#rrggbb)")

(defvar *color-scheme-callback-registered* nil
  "Whether the system color scheme callback has been registered.")

(defvar *font-size* "13px"
  "Font size for UI text (CSS value like \"13px\" or \"14px\").")


;; ----------------------------------------------------------------------
;;  QSS template with {{key}} substitution tokens
;; ----------------------------------------------------------------------

(defparameter *qss-template*
  "QMainWindow {
    background-color: {{window-bg}};
}
QMainWindow::separator {
    background-color: {{border}};
    width: 1px;
    height: 1px;
}

QMenuBar {
    background-color: {{window-bg}};
    border-bottom: 1px solid {{border}};
    padding: 2px 0;
}
QMenuBar::item {
    padding: 4px 10px;
    background: transparent;
    color: {{window-fg}};
    border-radius: 4px;
}
QMenuBar::item:selected {
    background-color: {{menu-highlight-bg}};
}

QMenu {
    background-color: {{menu-bg}};
    border: 1px solid {{border}};
    padding: 4px 0;
    border-radius: 6px;
}
QMenu::item {
    padding: 6px 28px 6px 14px;
    color: {{menu-fg}};
}
QMenu::item:selected {
    background-color: {{highlight}};
    color: {{highlight-text}};
}
QMenu::item:disabled {
    color: {{disabled-fg}};
}
QMenu::separator {
    height: 1px;
    background: {{separator}};
    margin: 4px 10px;
}

QDockWidget {
    background-color: {{window-bg}};
    color: {{dock-title-fg}};
    titlebar-close-icon: none;
    titlebar-normal-icon: none;
}
QDockWidget::title {
    background-color: {{dock-title-bg}};
    padding: 6px 10px;
    text-align: left;
    border-bottom: 1px solid {{border}};
}
QDockWidget::close-button, QDockWidget::float-button {
    background: transparent;
    border: none;
    padding: 2px;
}

QStatusBar {
    background-color: {{status-bg}};
    color: {{status-fg}};
    border-top: none;
    font-size: {{font-size}};
}
QStatusBar::item {
    border: none;
}
QStatusBar QLabel {
    color: {{status-fg}};
    background: transparent;
}

QLabel {
    color: {{window-fg}};
    background: transparent;
}

QPlainTextEdit {
    background-color: {{repl-bg}};
    color: {{repl-fg}};
    border: 1px solid {{input-border}};
    selection-background-color: {{highlight}};
    selection-color: {{highlight-text}};
    font-family: 'Courier New', monospace;
    font-size: {{font-size}};
}

QLineEdit {
    background-color: {{input-bg}};
    color: {{input-fg}};
    border: 1px solid {{input-border}};
    padding: 4px 8px;
    selection-background-color: {{highlight}};
    selection-color: {{highlight-text}};
    font-family: 'Courier New', monospace;
    font-size: {{font-size}};
}
QLineEdit:focus {
    border: 1px solid {{input-focus-border}};
}
QLineEdit:disabled {
    color: {{disabled-fg}};
}

QTreeWidget {
    background-color: {{tree-bg}};
    color: {{tree-fg}};
    border: none;
    outline: none;
    alternate-background-color: {{tree-alt-bg}};
    font-size: {{font-size}};
}
QTreeWidget::item {
    padding: 4px 6px;
    border-radius: 3px;
}
QTreeWidget::item:selected {
    background-color: {{highlight}};
    color: {{highlight-text}};
}
QTreeWidget::item:hover:!selected {
    background-color: {{tree-hover-bg}};
}

QScrollBar:vertical {
    background: {{scrollbar-bg}};
    width: 10px;
    margin: 0;
}
QScrollBar::handle:vertical {
    background: {{scrollbar-fg}};
    min-height: 30px;
    border-radius: 5px;
    margin: 2px;
}
QScrollBar::handle:vertical:hover {
    background: {{scrollbar-hover-fg}};
}
QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {
    height: 0px;
}
QScrollBar:horizontal {
    background: {{scrollbar-bg}};
    height: 10px;
    margin: 0;
}
QScrollBar::handle:horizontal {
    background: {{scrollbar-fg}};
    min-width: 30px;
    border-radius: 5px;
    margin: 2px;
}
QScrollBar::handle:horizontal:hover {
    background: {{scrollbar-hover-fg}};
}
QScrollBar::add-line:horizontal, QScrollBar::sub-line:horizontal {
    width: 0px;
}

QToolTip {
    background-color: {{tooltip-bg}};
    color: {{tooltip-fg}};
    border: 1px solid {{tooltip-border}};
    padding: 6px 8px;
    border-radius: 4px;
    font-size: {{font-size}};
}

QDialog {
    background-color: {{window-bg}};
    color: {{window-fg}};
}
QDialog QPushButton {
    background-color: {{button-bg}};
    color: {{button-fg}};
    border: 1px solid {{button-border}};
    padding: 6px 18px;
    border-radius: 4px;
    min-width: 80px;
}
QDialog QPushButton:hover {
    background-color: {{button-hover-bg}};
}
QDialog QPushButton:pressed {
    background-color: {{button-pressed-bg}};
}

QMessageBox {
    background-color: {{window-bg}};
    color: {{window-fg}};
}
QMessageBox QPushButton {
    background-color: {{button-bg}};
    color: {{button-fg}};
    border: 1px solid {{button-border}};
    padding: 6px 18px;
    border-radius: 4px;
    min-width: 80px;
}
QMessageBox QPushButton:hover {
    background-color: {{button-hover-bg}};
}
QMessageBox QPushButton:pressed {
    background-color: {{button-pressed-bg}};
}

QFileDialog {
    background-color: {{window-bg}};
    color: {{window-fg}};
}
QFileDialog QLineEdit {
    background-color: {{input-bg}};
    color: {{input-fg}};
    border: 1px solid {{input-border}};
    padding: 4px 6px;
}
QFileDialog QListView, QFileDialog QTreeView {
    background-color: {{tree-bg}};
    color: {{tree-fg}};
    alternate-background-color: {{tree-alt-bg}};
    selection-background-color: {{highlight}};
    selection-color: {{highlight-text}};
    outline: none;
}
QFileDialog QComboBox {
    background-color: {{input-bg}};
    color: {{input-fg}};
    border: 1px solid {{input-border}};
    padding: 4px 6px;
}
QFileDialog QPushButton {
    background-color: {{button-bg}};
    color: {{button-fg}};
    border: 1px solid {{button-border}};
    padding: 6px 18px;
    border-radius: 4px;
    min-width: 80px;
}
QFileDialog QPushButton:hover {
    background-color: {{button-hover-bg}};
}
QFileDialog QPushButton:pressed {
    background-color: {{button-pressed-bg}};
}
QFileDialog QHeaderView {
    background-color: {{tree-bg}};
    color: {{tree-fg}};
}
QFileDialog QLabel {
    color: {{window-fg}};
}
QFileDialog QToolBar {
    background: transparent;
    spacing: 4px;
}
QFileDialog QToolButton {
    color: {{window-fg}};
    background: transparent;
    border: 1px solid transparent;
    border-radius: 4px;
    padding: 4px;
}
QFileDialog QToolButton:hover {
    background: {{button-hover-bg}};
    border-color: {{button-border}};
}
QFileDialog QToolButton:pressed {
    background: {{button-pressed-bg}};
}")

;; ----------------------------------------------------------------------
;;  Template substitution
;; ----------------------------------------------------------------------

(defun %normalize-key (key)
  "Convert a key (keyword or string) to a template token string.
  :window-bg → \"window-bg\", \"window-bg\" → \"window-bg\"."
  (let* ((raw (etypecase key
                (string key)
                (symbol (string key))))
         (lower (string-downcase raw)))
    (if (and (> (length lower) 0) (char= (char lower 0) #\:))
        (subseq lower 1)
        lower)))

(defun %subst (string alist)
  "Replace all {{key}} tokens in STRING with values from ALIST (key . val)."
  (reduce (lambda (s pair)
            (destructuring-bind (key . val) pair
              (let* ((key-str (%normalize-key key))
                     (pat (concatenate 'string "{{" key-str "}}"))
                     (pat-len (length pat)))
                (with-output-to-string (out)
                  (let ((start 0))
                    (loop
                      (let ((pos (search pat s :start2 start)))
                        (if (null pos)
                            (progn
                              (write-string s out :start start)
                              (return))
                            (progn
                              (write-string s out :start start :end pos)
                              (write-string val out)
                              (setf start (+ pos pat-len)))))))))))
          alist
          :initial-value string))

;; ----------------------------------------------------------------------
;;  Palette definitions
;; ----------------------------------------------------------------------

(defun %dark-palette (accent)
  `((:viewport-bg . "#2d2d2d")
    (:window-bg . "#1e1e1e")
    (:window-fg . "#e0e0e0")
    (:menu-bg . "#2d2d2d")
    (:menu-fg . "#e0e0e0")
    (:menu-highlight-bg . "#383838")
    (:disabled-fg . "#6e6e6e")
    (:separator . "#3e3e3e")
    (:border . "#555555")
    (:dock-title-bg . "#2d2d2d")
    (:dock-title-fg . "#cccccc")
    (:status-bg . "#007acc")
    (:status-fg . "#ffffff")
    (:input-bg . "#1a1a1a")
    (:input-fg . "#f0f0f0")
    (:input-border . "#555555")
    (:input-focus-border . ,accent)
    (:scrollbar-bg . "transparent")
    (:scrollbar-fg . "#424242")
    (:scrollbar-hover-fg . "#565656")
    (:tree-bg . "#252526")
    (:tree-fg . "#cccccc")
    (:tree-alt-bg . "#2d2d2d")
    (:tree-hover-bg . "#2a2d2e")
    (:tooltip-bg . "#383838")
    (:tooltip-fg . "#e0e0e0")
    (:tooltip-border . "#555555")
    (:repl-bg . "#1a1a1a")
    (:repl-fg . "#f0f0f0")
    (:placeholder-fg . "#888888")
    (:tab-bg . "#2d2d2d")
    (:tab-fg . "#999999")
    (:tab-selected-bg . "#1e1e1e")
    (:tab-selected-fg . "#ffffff")
    (:axis-x-color . "#E53935")
    (:axis-y-color . "#43A047")
    (:axis-z-color . "#1E88E5")
    (:highlight . ,accent)
    (:highlight-text . "#ffffff")
    (:button-bg . "#383838")
    (:button-fg . "#e0e0e0")
    (:button-border . "#555555")
    (:button-hover-bg . "#454545")
    (:button-pressed-bg . "#2a2a2a")
    (:font-size . ,*font-size*)))

(defun %light-palette (accent)
  `((:viewport-bg . "#f0f0f0")
    (:window-bg . "#f3f3f3")
    (:window-fg . "#1a1a1a")
    (:menu-bg . "#f0f0f0")
    (:menu-fg . "#1a1a1a")
    (:menu-highlight-bg . "#e0e0e0")
    (:disabled-fg . "#a0a0a0")
    (:separator . "#d0d0d0")
    (:border . "#c0c0c0")
    (:dock-title-bg . "#d4d4d4")
    (:dock-title-fg . "#1a1a1a")
    (:status-bg . "#0078d4")
    (:status-fg . "#ffffff")
    (:input-bg . "#ffffff")
    (:input-fg . "#1a1a1a")
    (:input-border . "#c0c0c0")
    (:input-focus-border . ,accent)
    (:scrollbar-bg . "transparent")
    (:scrollbar-fg . "#c0c0c0")
    (:scrollbar-hover-fg . "#a0a0a0")
    (:tree-bg . "#ffffff")
    (:tree-fg . "#333333")
    (:tree-alt-bg . "#f5f5f5")
    (:tree-hover-bg . "#e8f0fe")
    (:tooltip-bg . "#f0f0f0")
    (:tooltip-fg . "#1a1a1a")
    (:tooltip-border . "#c0c0c0")
    (:repl-bg . "#f9f9f9")
    (:repl-fg . "#1a1a1a")
    (:placeholder-fg . "#aaaaaa")
    (:tab-bg . "#e8e8e8")
    (:tab-fg . "#666666")
    (:tab-selected-bg . "#f3f3f3")
    (:tab-selected-fg . "#1a1a1a")
    (:axis-x-color . "#E53935")
    (:axis-y-color . "#43A047")
    (:axis-z-color . "#1E88E5")
    (:highlight . ,accent)
    (:highlight-text . "#ffffff")
    (:button-bg . "#e0e0e0")
    (:button-fg . "#1a1a1a")
    (:button-border . "#c0c0c0")
    (:button-hover-bg . "#d0d0d0")
    (:button-pressed-bg . "#b0b0b0")
    (:font-size . ,*font-size*)))

;; ----------------------------------------------------------------------
;;  Theme generation and application
;; ----------------------------------------------------------------------

(defun generate-qss (mode &key (accent *accent-color*))
  "Generate the complete QSS string for the given MODE and ACCENT color."
  (let ((palette (ecase mode
                   (:dark (%dark-palette accent))
                   (:light (%light-palette accent)))))
    (%subst *qss-template* palette)))

(defun %resolve-mode (mode)
  "Resolve :auto to :dark or :light based on system preference.
Falls back to :light if system scheme is unknown or unavailable."
  (if (eq mode :auto)
      (if (and *viewer*
               (= 2 (%viewer-color-scheme *viewer*)))
          :dark
          :light)
      mode))

(defun %hex-to-rgb (hex)
  "Parse a CSS hex color \"#rrggbb\" into (values r g b) as integers 0-255."
  (values (parse-integer (subseq hex 1 3) :radix 16)
          (parse-integer (subseq hex 3 5) :radix 16)
          (parse-integer (subseq hex 5 7) :radix 16)))

(defun %apply-viewport-bg (palette-alist)
  "Set the 3D viewport background color from the palette."
  (let ((bg (cdr (assoc :viewport-bg palette-alist))))
    (when bg
      (multiple-value-bind (r g b) (%hex-to-rgb bg)
        (let ((view (%viewer-get-view *viewer*)))
          (when view
            (cl-occt.impl:%v3d-view-set-bg-color
             view
             (coerce (/ r 255.0) 'double-float)
             (coerce (/ g 255.0) 'double-float)
             (coerce (/ b 255.0) 'double-float))))))))

(defun %apply-axis-colors (palette-alist)
  "Set the trihedron axis colors from the palette."
  (dolist (pair '((:axis-x-color . 0)
                  (:axis-y-color . 1)
                  (:axis-z-color . 2)))
    (let ((hex (cdr (assoc (car pair) palette-alist))))
      (when hex
        (multiple-value-bind (r g b) (%hex-to-rgb hex)
          (let ((rf (coerce (/ r 255.0) 'double-float))
                (gf (coerce (/ g 255.0) 'double-float))
                (bf (coerce (/ b 255.0) 'double-float)))
            (%viewer-set-trihedron-text-color *viewer* (cdr pair) rf gf bf)
            (let ((tri (%viewer-get-trihedron *viewer*)))
              (when tri
                (cl-occt.impl:%ais-trihedron-set-datum-part-color
                 tri (cdr pair) rf gf bf)))))))))

(defun %apply-placeholder-color (palette-alist)
  "Set the placeholder text color from the palette."
  (let ((hex (cdr (assoc :placeholder-fg palette-alist))))
    (when hex
      (multiple-value-bind (r g b) (%hex-to-rgb hex)
        (%viewer-set-placeholder-color *viewer* r g b)))))

(defun apply-theme (mode &key accent)
  "Apply a theme. MODE is :dark, :light, or :auto.
ACCENT is an optional CSS hex color string, e.g. \"#0078d4\".
Returns (values effective-mode effective-accent)."
  (let* ((effective-mode (%resolve-mode mode))
         (effective-accent (or accent *accent-color*))
         (palette (ecase effective-mode
                    (:dark (%dark-palette effective-accent))
                    (:light (%light-palette effective-accent)))))
    (setf *theme-mode* mode
          *accent-color* effective-accent)
    (when *viewer*
      (%viewer-set-stylesheet *viewer* (%subst *qss-template* palette))
      (%apply-viewport-bg palette)
      (%apply-axis-colors palette)
      (%apply-placeholder-color palette))
    (values effective-mode effective-accent)))

(defun set-accent (color-hex)
  "Change the accent color and reapply the current theme.
COLOR-HEX is a CSS hex string like \"#FF6600\".
Returns the accent color string."
  (setf *accent-color* color-hex)
  (apply-theme *theme-mode*)
  color-hex)

(defun theme-dark (&optional (accent *accent-color*))
  "Switch to dark theme, optionally with a new accent color."
  (apply-theme :dark :accent accent))

(defun theme-light (&optional (accent *accent-color*))
  "Switch to light theme, optionally with a new accent color."
  (apply-theme :light :accent accent))

(defun theme-auto (&optional (accent *accent-color*))
  "Follow the system dark/light preference."
  (apply-theme :auto :accent accent))

(defun set-font-size (size)
  "Set the UI font size and reapply the current theme.
SIZE is a CSS font-size string like \"15px\" or \"1.1em\". Returns the size."
  (setf *font-size* size)
  (apply-theme *theme-mode*)
  size)

;; ----------------------------------------------------------------------
;;  System color scheme change callback
;;  Re-applies the theme automatically when the OS switches dark/light.
;; ----------------------------------------------------------------------

(cffi:defcallback %on-color-scheme-change :void ((scheme :int))
  (declare (ignore scheme))
  (when (eq *theme-mode* :auto)
    (apply-theme :auto)))

(defun register-color-scheme-callback ()
  "Register the callback that fires when the OS color scheme changes.
Safe to call multiple times — only registers once."
  (unless *color-scheme-callback-registered*
    (setf *color-scheme-callback-registered* t)
    (when *viewer*
      (%viewer-set-color-scheme-callback
       *viewer*
       (cffi:callback %on-color-scheme-change)))))
