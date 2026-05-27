(in-package :clotcad)

;; ─── pnt tests ───

(deftest pnt-creates-sketch-point
  (let ((p (pnt 3.5 7.0)))
    (assert-true (sketch-point-p p))
    (assert-equal 3.5d0 (sketch-point-x p))
    (assert-equal 7.0d0 (sketch-point-y p))))

(deftest pnt-double-float-coercion
  (let ((p (pnt 3 7)))
    (assert-equal 3.0d0 (sketch-point-x p))
    (assert-equal 7.0d0 (sketch-point-y p))))

;; ─── rect primitive (mocked) ───

(deftest rect-creates-four-edges
  (let ((calls nil)
        (wire-calls nil))
    (let ((old-edge (symbol-function 'cl-occt:make-edge))
          (old-wire (symbol-function 'cl-occt:make-wire)))
      (setf (symbol-function 'cl-occt:make-edge)
            (lambda (x1 y1 x2 y2)
              (push (list :edge x1 y1 x2 y2) calls)
              (list :edge x1 y1 x2 y2)))
      (setf (symbol-function 'cl-occt:make-wire)
            (lambda (&rest edges)
              (push (cons :wire edges) wire-calls)
              (cons :wire edges)))
      (unwind-protect
           (let ((result (rect (pnt 0 0) 10 20)))
             (assert-equal 4 (length calls)
                            "rect should call make-edge 4 times")
             (assert-eql :wire (first result))
             (assert-equal 4 (length (cdr result))
                            "rect should create a wire with 4 edges")
             (assert-equal 4 (length wire-calls)
                            "rect should call make-wire once"))
        (setf (symbol-function 'cl-occt:make-edge) old-edge)
        (setf (symbol-function 'cl-occt:make-wire) old-wire)))))

(deftest rect-correct-coordinates
  (let ((edges nil))
    (let ((old (symbol-function 'cl-occt:make-edge)))
      (setf (symbol-function 'cl-occt:make-edge)
            (lambda (x1 y1 x2 y2)
              (push (list x1 y1 x2 y2) edges)
              (list :edge x1 y1 x2 y2)))
      (unwind-protect
           (progn
             (rect (pnt 1 2) 10 20)
             (assert-equal 4 (length edges))
             (assert-equal '(1 2 11 2) (first edges))
             (assert-equal '(11 2 11 22) (second edges))
             (assert-equal '(11 22 1 22) (third edges))
             (assert-equal '(1 22 1 2) (fourth edges)))
        (setf (symbol-function 'cl-occt:make-edge) old)))))

;; ─── circle primitive (mocked) ───

(deftest circle-creates-one-edge
  (let ((circle-calls nil)
        (wire-calls nil))
    (let ((old-circle (symbol-function 'cl-occt:make-circle-edge))
          (old-wire (symbol-function 'cl-occt:make-wire)))
      (setf (symbol-function 'cl-occt:make-circle-edge)
            (lambda (x y r)
              (push (list :circle x y r) circle-calls)
              (list :circle-edge x y r)))
      (setf (symbol-function 'cl-occt:make-wire)
            (lambda (&rest edges)
              (push edges wire-calls)
              (cons :wire edges)))
      (unwind-protect
           (let ((result (circle (pnt 0 0) 5)))
             (assert-equal 1 (length circle-calls)
                            "circle should call make-circle-edge once")
             (assert-equal '(0 0 5) (cdar circle-calls))
             (assert-eql :wire (first result)))
        (setf (symbol-function 'cl-occt:make-circle-edge) old-circle)
        (setf (symbol-function 'cl-occt:make-wire) old-wire)))))

;; ─── polygon primitive (mocked) ───

(deftest polygon-creates-n-edges-for-n-points
  (let ((edges nil)
        (wire-args nil))
    (let ((old-edge (symbol-function 'cl-occt:make-edge))
          (old-wire (symbol-function 'cl-occt:make-wire)))
      (setf (symbol-function 'cl-occt:make-edge)
            (lambda (x1 y1 x2 y2)
              (push (list x1 y1 x2 y2) edges)
              (list :edge x1 y1 x2 y2)))
      (setf (symbol-function 'cl-occt:make-wire)
            (lambda (&rest es)
              (setf wire-args es)
              (cons :wire es)))
      (unwind-protect
           (progn
             (polygon (pnt 0 0) (pnt 5 0) (pnt 2.5 5))
             (assert-equal 3 (length edges)
                            "triangle should create 3 edges")
             (assert-equal '(5 0 2.5 5) (second edges)
                            "edge2 should connect B→C")
             (assert-equal '(2.5 5 0 0) (third edges)
                            "edge3 should connect C→A (close)"))
        (setf (symbol-function 'cl-occt:make-edge) old-edge)
        (setf (symbol-function 'cl-occt:make-wire) old-wire)))))

(deftest polygon-errors-with-less-than-3-points
  (assert-error (polygon (pnt 0 0) (pnt 5 0))))

;; ─── line-chain primitive ───

(deftest line-chain-open-creates-2-edges-for-3-points
  (let ((edges nil))
    (let ((old-edge (symbol-function 'cl-occt:make-edge))
          (old-wire (symbol-function 'cl-occt:make-wire)))
      (setf (symbol-function 'cl-occt:make-edge)
            (lambda (x1 y1 x2 y2)
              (push (list x1 y1 x2 y2) edges)
              (list :edge x1 y1 x2 y2)))
      (setf (symbol-function 'cl-occt:make-wire)
            (lambda (&rest es) (cons :wire es)))
      (unwind-protect
           (progn
             (line-chain (pnt 0 0) (pnt 5 0) (pnt 5 5))
             (assert-equal 2 (length edges)
                            "open chain of 3 points should create 2 edges"))
        (setf (symbol-function 'cl-occt:make-edge) old-edge)
        (setf (symbol-function 'cl-occt:make-wire) old-wire)))))

(deftest line-chain-closed-creates-3-edges-for-3-points
  (let ((edges nil))
    (let ((old-edge (symbol-function 'cl-occt:make-edge))
          (old-wire (symbol-function 'cl-occt:make-wire)))
      (setf (symbol-function 'cl-occt:make-edge)
            (lambda (x1 y1 x2 y2)
              (push (list x1 y1 x2 y2) edges)
              (list :edge x1 y1 x2 y2)))
      (setf (symbol-function 'cl-occt:make-wire)
            (lambda (&rest es) (cons :wire es)))
      (unwind-protect
           (progn
             (line-chain (pnt 0 0) (pnt 5 0) (pnt 5 5) :closed t)
             (assert-equal 3 (length edges)
                            "closed chain of 3 points should create 3 edges"))
        (setf (symbol-function 'cl-occt:make-edge) old-edge)
        (setf (symbol-function 'cl-occt:make-wire) old-wire)))))

(deftest line-chain-errors-with-less-than-2-points
  (assert-error (line-chain (pnt 0 0))))

;; ─── slot primitive ───

(deftest slot-creates-wire
  (let ((edge-calls 0)
        (arc-calls 0))
    (let ((old-edge (symbol-function 'cl-occt:make-edge))
          (old-arc (symbol-function 'cl-occt:make-circular-arc))
          (old-wire (symbol-function 'cl-occt:make-wire)))
      (setf (symbol-function 'cl-occt:make-edge)
            (lambda (x1 y1 x2 y2)
              (incf edge-calls)
              (list :edge x1 y1 x2 y2)))
      (setf (symbol-function 'cl-occt:make-circular-arc)
            (lambda (x1 y1 x2 y2 x3 y3)
              (incf arc-calls)
              (list :arc x1 y1 x2 y2 x3 y3)))
      (setf (symbol-function 'cl-occt:make-wire)
            (lambda (&rest es)
              (cons :wire es)))
      (unwind-protect
           (progn
             (slot (pnt 0 0) 12 6 2)
             (assert-equal 4 edge-calls "slot should create 4 straight edges")
             (assert-equal 4 arc-calls "slot should create 4 corner arcs"))
        (setf (symbol-function 'cl-occt:make-edge) old-edge)
        (setf (symbol-function 'cl-occt:make-circular-arc) old-arc)
        (setf (symbol-function 'cl-occt:make-wire) old-wire)))))

;; ─── %resolve-sketch-point ───

(deftest resolve-sketch-point-with-pnt
  (multiple-value-bind (x y) (%resolve-sketch-point (pnt 3.5 7.0))
    (assert-equal 3.5d0 x)
    (assert-equal 7.0d0 y)))

(deftest resolve-sketch-point-errors-without-frame
  (assert-error (%resolve-sketch-point :some-vertex)))

;; ─── %project-vertex-to-sketch ───

(deftest project-vertex-to-sketch
  (let ((old-resolve (symbol-function 'resolve-shape))
        (old-vertex (symbol-function 'cl-occt:vertex-point)))
    (setf (symbol-function 'resolve-shape)
          (lambda (d) (declare (ignore d)) :mock-vertex))
    (setf (symbol-function 'cl-occt:vertex-point)
          (lambda (v) (declare (ignore v)) (values 5.0d0 10.0d0 0.0d0)))
    (unwind-protect
         (let* ((frame (make-instance 'frame
                         :origin '(0.0d0 0.0d0 0.0d0)
                         :x-axis '(1.0d0 0.0d0 0.0d0)
                         :y-axis '(0.0d0 1.0d0 0.0d0)
                         :z-axis '(0.0d0 0.0d0 1.0d0))))
           (multiple-value-bind (u v)
               (%project-vertex-to-sketch :dummy frame)
             (assert-equal 5.0d0 u "vertex x=5 should project to u=5")
             (assert-equal 10.0d0 v "vertex y=10 should project to v=10")))
      (setf (symbol-function 'resolve-shape) old-resolve)
      (setf (symbol-function 'cl-occt:vertex-point) old-vertex))))

;; ─── %assemble-sketch-result ───

(deftest assemble-sketch-result-face-default
  (let ((calls nil))
    (let ((old-make-face (symbol-function 'cl-occt:make-face-on-plane))
          (old-cut (symbol-function 'cl-occt:cut)))
      (setf (symbol-function 'cl-occt:make-face-on-plane)
            (lambda (w ox oy oz nx ny nz)
              (push (list :make-face w ox oy oz nx ny nz) calls)
              (list :face w)))
      (setf (symbol-function 'cl-occt:cut)
            (lambda (a b)
              (push (list :cut a b) calls)
              (list :result a b)))
      (unwind-protect
           (let* ((frame (make-instance 'frame
                            :origin '(0.0d0 0.0d0 0.0d0)
                            :x-axis '(1.0d0 0.0d0 0.0d0)
                            :y-axis '(0.0d0 1.0d0 0.0d0)
                            :z-axis '(0.0d0 0.0d0 1.0d0)))
                   (result (%assemble-sketch-result
                            (list :outer-wire :hole-wire) :face frame)))
              (assert-equal 3 (length calls)
                             "should call make-face twice + cut once")
              (assert-equal :result (first result)))
        (setf (symbol-function 'cl-occt:make-face-on-plane) old-make-face)
        (setf (symbol-function 'cl-occt:cut) old-cut)))))

(deftest assemble-sketch-result-faces-mode
  (let ((calls nil))
    (let ((old (symbol-function 'cl-occt:make-face-on-plane)))
      (setf (symbol-function 'cl-occt:make-face-on-plane)
            (lambda (w ox oy oz nx ny nz)
              (push w calls)
              (list :face w)))
      (unwind-protect
           (let* ((frame (make-instance 'frame
                            :origin '(0.0d0 0.0d0 0.0d0)
                            :x-axis '(1.0d0 0.0d0 0.0d0)
                            :y-axis '(0.0d0 1.0d0 0.0d0)
                            :z-axis '(0.0d0 0.0d0 1.0d0)))
                   (result (%assemble-sketch-result
                            (list :w1 :w2) :faces frame)))
              (assert-equal 2 (length result))
              (assert-equal 2 (length calls)))
        (setf (symbol-function 'cl-occt:make-face-on-plane) old)))))

(deftest assemble-sketch-result-wire-mode
  (let ((make-face-calls nil)
        (face-wires-calls nil))
    (let ((old-make-face (symbol-function 'cl-occt:make-face-on-plane))
          (old-face-wires (symbol-function 'cl-occt:face-wires)))
      (setf (symbol-function 'cl-occt:make-face-on-plane)
            (lambda (w ox oy oz nx ny nz)
              (push w make-face-calls)
              (list :face-made w)))
      (setf (symbol-function 'cl-occt:face-wires)
            (lambda (face)
              (push face face-wires-calls)
              (list :extracted-wire)))
      (unwind-protect
           (let* ((frame (make-instance 'frame
                            :origin '(0.0d0 0.0d0 0.0d0)
                            :x-axis '(1.0d0 0.0d0 0.0d0)
                            :y-axis '(0.0d0 1.0d0 0.0d0)
                            :z-axis '(0.0d0 0.0d0 1.0d0)))
                   (result (%assemble-sketch-result
                            (list :my-wire) :wire frame)))
              (assert-eql :extracted-wire result))
        (setf (symbol-function 'cl-occt:make-face-on-plane) old-make-face)
        (setf (symbol-function 'cl-occt:face-wires) old-face-wires)))))

(deftest assemble-sketch-result-empty-errors
  (let ((frame (make-instance 'frame
                :origin '(0 0 0)
                :x-axis '(1 0 0)
                :y-axis '(0 1 0)
                :z-axis '(0 0 1))))
    (assert-error (%assemble-sketch-result nil :face frame))
    (assert-error (%assemble-sketch-result nil :faces frame))
    (assert-error (%assemble-sketch-result nil :wire frame))))

;; ─── sketch-on-face integration test (mocked) ───

(deftest sketch-on-face-binds-frame
    (let ((old-resolve (symbol-function 'resolve-shape))
          (old-make-frame (symbol-function 'make-frame-on-face))
          (old-sketch (symbol-function 'cl-occt:make-face-on-plane))
          (projected-point nil))
      (setf (symbol-function 'resolve-shape) (lambda (d) (declare (ignore d)) :mock-face))
      (setf (symbol-function 'make-frame-on-face)
            (lambda (face &rest args)
              (declare (ignore face args))
              (make-instance 'frame
                :origin '(0.0d0 0.0d0 0.0d0)
                :x-axis '(1.0d0 0.0d0 0.0d0)
                :y-axis '(0.0d0 1.0d0 0.0d0)
                :z-axis '(0.0d0 0.0d0 1.0d0))))
      (let ((old-edge (symbol-function 'cl-occt:make-edge))
            (old-wire (symbol-function 'cl-occt:make-wire)))
        (setf (symbol-function 'cl-occt:make-edge)
              (lambda (x1 y1 x2 y2)
                (setf projected-point (list x1 y1 x2 y2))
                (list :edge x1 y1 x2 y2)))
        (setf (symbol-function 'cl-occt:make-wire)
              (lambda (&rest es) (cons :wire es)))
        (setf (symbol-function 'cl-occt:make-face-on-plane)
              (lambda (w ox oy oz nx ny nz)
                (declare (ignore ox oy oz nx ny nz))
                (list :face w)))
        (unwind-protect
             (progn
               (sketch-on-face :mock-face (rect (pnt 2 3) 10 20))
               (assert-true projected-point
                            "sketch-on-face should evaluate rect with frame bound")
               (assert-equal '(2.0d0 3.0d0 12.0d0 23.0d0) projected-point))
          (setf (symbol-function 'resolve-shape) old-resolve)
          (setf (symbol-function 'make-frame-on-face) old-make-frame)
          (setf (symbol-function 'cl-occt:make-edge) old-edge)
          (setf (symbol-function 'cl-occt:make-wire) old-wire)
          (setf (symbol-function 'cl-occt:make-face-on-plane) old-sketch)))))

;; ─── extrude-from-face tests (mocked) ───

(deftest extrude-from-face-exists
  (assert-true (fboundp 'extrude-from-face)))

(deftest extrude-from-face-calls-prism-and-cut
  (let ((calls nil))
    (let ((old-resolve (symbol-function 'resolve-shape))
          (old-make-frame (symbol-function 'make-frame-on-face))
          (old-prism (symbol-function 'cl-occt:make-prism))
          (old-cut (symbol-function 'cl-occt:cut))
          (old-parse (symbol-function '%parse-compound-symbol)))
      (setf (symbol-function 'resolve-shape) (lambda (d) (declare (ignore d)) :mock-face))
      (setf (symbol-function 'make-frame-on-face)
            (lambda (face &rest args)
              (declare (ignore face args))
              (make-instance 'frame
                :origin '(0.0d0 0.0d0 0.0d0)
                :x-axis '(1.0d0 0.0d0 0.0d0)
                :y-axis '(0.0d0 1.0d0 0.0d0)
                :z-axis '(0.0d0 0.0d0 1.0d0))))
      (setf (symbol-function '%parse-compound-symbol)
            (lambda (sym)
              (declare (ignore sym))
              (values :mock-model :mock-face)))
      (setf (symbol-function 'cl-occt:make-prism)
            (lambda (shape dx dy dz)
              (push (list :prism shape dx dy dz) calls)
              :mock-extruded))
      (setf (symbol-function 'cl-occt:cut)
            (lambda (a b)
              (push (list :cut a b) calls)
              :mock-result))
      (unwind-protect
           (let ((result (extrude-from-face :box/top-face :mock-sketch
                            :depth 5.0d0)))
             (assert-eql :mock-result result)
             (assert-equal 2 (length calls)
                            "should call make-prism and cut")
             (destructuring-bind (prism-call cut-call) (reverse calls)
               (assert-eql :prism (first prism-call))
               (assert-equal 5.0d0 (abs (fourth prism-call))
                              "extrusion depth should match with negated normal")
               (assert-eql :cut (first cut-call))))
        (setf (symbol-function 'resolve-shape) old-resolve)
        (setf (symbol-function 'make-frame-on-face) old-make-frame)
        (setf (symbol-function 'cl-occt:make-prism) old-prism)
        (setf (symbol-function 'cl-occt:cut) old-cut)
        (setf (symbol-function '%parse-compound-symbol) old-parse)))))

;; ─── Package tests ───

(deftest sketch-symbols-exported-from-clotcad
  (dolist (sym '(sketch-point sketch-point-x sketch-point-y
                 pnt sketch-on-face rect circle slot polygon line-chain
                 extrude-from-face))
    (assert-true (find-symbol (string sym) :clotcad)
                 (format nil "~S should be exported from :clotcad" sym))))

(deftest sketch-symbols-accessible-in-clotcad-user
  (let ((pkg (find-package :clotcad-user)))
    (dolist (sym '(pnt sketch-on-face rect circle slot polygon line-chain
                 extrude-from-face))
      (let ((found (find-symbol (string sym) pkg)))
        (assert-true found
                     (format nil "~S should be accessible in :clotcad-user" sym))
        (assert-eql :internal (nth-value 1 (find-symbol (string sym) pkg))
                    (format nil "~S should be internal (via :use) in :clotcad-user" sym))))))
