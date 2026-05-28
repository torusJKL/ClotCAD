(in-package :clotcad)

(defvar *text-font-fallbacks*
  '("sans-serif" "Arial" "DejaVu Sans" "Liberation Sans" "FreeSans")
  "Font names to try when `make-3d-text` is called without `:font`.")

(defun %resolve-font (name-string size)
  (let ((font (cl-occt:make-brep-font-from-name name-string size)))
    (when font
      (return-from %resolve-font font)))
  nil)

(defun %resolve-font-with-fallback (size)
  (dolist (name *text-font-fallbacks*)
    (let ((font (cl-occt:make-brep-font-from-name name size)))
      (when font
        (return-from %resolve-font-with-fallback font))))
  (let ((available (cl-occt:list-available-fonts)))
    (error "Could not load any fallback font.~@[ Available fonts: ~{~S~^, ~}~]"
           (and available (list available))))
  nil)

(defun %plane->values (plane)
  (cond
    ((keywordp plane)
     (ecase plane
       (:xy (values '(0 0 0) '(0 0 1) '(1 0 0)))
       (:xz (values '(0 0 0) '(0 1 0) '(1 0 0)))
       (:yz (values '(0 0 0) '(1 0 0) '(0 1 0)))))
    ((typep plane 'frame)
     (values (frame-origin plane)
             (frame-z-axis plane)
             (frame-x-axis plane)))
    ((and (shape-p plane)
          (eq (cl-occt:shape-type plane) :face))
     (let ((f (make-frame-on-face plane)))
       (values (frame-origin f)
               (frame-z-axis f)
               (frame-x-axis f))))
    (t
     (error "~S is not a valid plane specifier: expected a keyword (:xy/:xz/:yz), a face, or a frame"
            plane))))

(defun make-3d-text (string &key font (size 10) (thickness 5)
                                      (h-align :center) (v-align :center)
                                      (plane :xz))
  (let ((resolved-font (if font
                           (%resolve-font font size)
                           (%resolve-font-with-fallback size))))
    (unless resolved-font
      (error "Could not load font~@[ ~S~]" font))
    (multiple-value-bind (pos normal x-dir) (%plane->values plane)
      (cl-occt:make-text-shape-3d
       resolved-font string (coerce thickness 'double-float)
       :h-align h-align :v-align v-align
       :position pos :normal normal :x-direction x-dir))))
