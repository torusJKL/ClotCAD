(in-package :clotcad)

;; ─── Test shapes ───

(defun %test-box-shape ()
  (cl-occt:make-box 10 20 30))

(defun %test-cylinder-shape ()
  (cl-occt:make-cylinder 5 20))

;; ─── Type predicate tests ───

(deftest query-face-p-on-box
  (let ((faces (query-shape (%test-box-shape) :where (list (face-p)))))
    (assert-equal 6 (length faces))))

(deftest query-edge-p-on-box
  (let ((edges (query-shape (%test-box-shape) :where (list (edge-p)))))
    (assert-equal 12 (length edges))))

(deftest query-vertex-p-on-box
  (let ((verts (query-shape (%test-box-shape) :where (list (vertex-p)))))
    (assert-equal 8 (length verts))))

(deftest query-face-p-on-cylinder
  (let ((faces (query-shape (%test-cylinder-shape) :where (list (face-p)))))
    (assert-equal 3 (length faces))))

(deftest query-edge-p-on-cylinder
  (let ((edges (query-shape (%test-cylinder-shape) :where (list (edge-p)))))
    (assert-equal 2 (length edges))))

;; ─── normal-along tests ───

(deftest query-normal-along-plus-z-on-box
  (let ((faces (query-shape (%test-box-shape)
                            :where (list (face-p) (normal-along 0 0 1)))))
    (assert-equal 1 (length faces))
    (assert-eq :face (cl-occt:shape-type (first faces)))))

(deftest query-normal-along-minus-z-on-box
  (let ((faces (query-shape (%test-box-shape)
                            :where (list (face-p) (normal-along 0 0 -1)))))
    (assert-equal 1 (length faces))))

;; ─── surface-type tests ───

(deftest query-surface-type-plane-on-box
  (let ((faces (query-shape (%test-box-shape)
                            :where (list (face-p) (surface-type :plane)))))
    (assert-equal 6 (length faces))))

(deftest query-surface-type-cylinder-on-cylinder
  (let ((faces (query-shape (%test-cylinder-shape)
                            :where (list (face-p) (surface-type :cylinder)))))
    (assert-equal 1 (length faces))))

;; ─── curve-type tests ───

(deftest query-curve-type-line-on-box
  (let ((edges (query-shape (%test-box-shape)
                            :where (list (edge-p) (curve-type :line)))))
    (assert-equal 12 (length edges))))

(deftest query-curve-type-circle-on-cylinder
  (let ((edges (query-shape (%test-cylinder-shape)
                            :where (list (edge-p) (curve-type :circle)))))
    (assert-equal 2 (length edges))))

;; ─── edge-length tests ───

(deftest query-longer-than-on-box
  (let ((edges (query-shape (%test-box-shape)
                            :where (list (edge-p) (longer-than 15)))))
    (assert-equal 4 (length edges))))

(deftest query-shorter-than-on-box
  (let ((edges (query-shape (%test-box-shape)
                            :where (list (edge-p) (shorter-than 15)))))
    (assert-equal 8 (length edges))))

;; ─── face-area tests ───

(deftest query-larger-than-on-box
  (let ((faces (query-shape (%test-box-shape)
                            :where (list (face-p) (larger-than 200)))))
    (assert-equal 4 (length faces))))

(deftest query-smaller-than-on-box
  (let ((faces (query-shape (%test-box-shape)
                            :where (list (face-p) (smaller-than 300)))))
    (assert-equal 2 (length faces))))

;; ─── max-by / min-by tests ───

(deftest query-max-by-face-area-on-box
  (let ((faces (query-shape (%test-box-shape)
                            :where (list (face-p) (max-by #'cl-occt:face-area)))))
    (assert-equal 1 (length faces))))

(deftest query-min-by-edge-length-on-box
  (let ((edges (query-shape (%test-box-shape)
                            :where (list (edge-p) (min-by #'cl-occt:edge-length)))))
    (assert-equal 1 (length edges))))

;; ─── center predicate tests ───

(deftest query-z-center-on-box
  (let ((faces (query-shape (%test-box-shape)
                            :where (list (face-p) (z-center 15)))))
    (assert-equal 1 (length faces))))

(deftest query-z-center-on-box-with-tolerance
  (let ((faces (query-shape (%test-box-shape)
                            :where (list (face-p) (z-center 15 :tolerance 1))))
        (faces-near (query-shape (%test-box-shape)
                                 :where (list (face-p) (z-center 14 :tolerance 2)))))
    (assert-equal 1 (length faces))
    (assert-equal 2 (length faces-near))))

;; ─── edge-along tests ───

(deftest query-edge-along-z-on-box
  (let ((edges (query-shape (%test-box-shape)
                            :where (list (edge-p) (edge-along 0 0 1)))))
    (assert-equal 4 (length edges))))

(deftest query-edge-along-x-on-box
  (let ((edges (query-shape (%test-box-shape)
                            :where (list (edge-p) (edge-along 1 0 0)))))
    (assert-equal 4 (length edges))))

;; ─── radius-around tests ───

(deftest query-radius-around-on-cylinder
  (let ((edges (query-shape (%test-cylinder-shape)
                            :where (list (edge-p) (radius-around 5)))))
    (assert-equal 2 (length edges))))

(deftest query-radius-around-on-cylinder-with-tolerance
  (let ((edges (query-shape (%test-cylinder-shape)
                            :where (list (edge-p) (radius-around 5 :tolerance 0.5)))))
    (assert-equal 2 (length edges))))

;; ─── Convenience accessor tests ───

(deftest top-face-on-box
  (let ((face (top-face (%test-box-shape))))
    (assert-true face)
    (assert-eq :face (cl-occt:shape-type face))))

(deftest bottom-face-on-box
  (let ((face (bottom-face (%test-box-shape))))
    (assert-true face)
    (assert-eq :face (cl-occt:shape-type face))))

(deftest longest-edge-on-box
  (let ((edge (longest-edge (%test-box-shape))))
    (assert-true edge)
    (assert-eq :edge (cl-occt:shape-type edge))))

(deftest shortest-edge-on-box
  (let ((edge (shortest-edge (%test-box-shape))))
    (assert-true edge)
    (assert-eq :edge (cl-occt:shape-type edge))))

(deftest largest-face-on-box
  (let ((face (largest-face (%test-box-shape))))
    (assert-true face)
    (assert-eq :face (cl-occt:shape-type face))))

(deftest smallest-face-on-box
  (let ((face (smallest-face (%test-box-shape))))
    (assert-true face)
    (assert-eq :face (cl-occt:shape-type face))))

(deftest top-face-on-cylinder
  (let ((face (top-face (%test-cylinder-shape))))
    (assert-true face)
    (assert-eq :face (cl-occt:shape-type face))))

(deftest longest-edge-on-cylinder
  (let ((edge (longest-edge (%test-cylinder-shape))))
    (assert-eq :edge (cl-occt:shape-type edge))))

;; ─── Coordinate system test ───

(deftest query-with-local-coordinate-system
  (let ((faces (query-shape (%test-box-shape)
                            :where (list (face-p) (normal-along 0 0 1))
                            :coordinate-system :local)))
    (assert-equal 1 (length faces))))

(deftest query-with-global-coordinate-system
  (let ((faces (query-shape (%test-box-shape)
                            :where (list (face-p) (normal-along 0 0 1))
                            :coordinate-system :global)))
    (assert-equal 1 (length faces))))

;; ─── Combined predicates with selector ───

(deftest query-combined-predicates
  (let ((faces (query-shape (%test-box-shape)
                            :where (list (face-p) (surface-type :plane)
                                         (normal-along 0 0 1)
                                         (max-by #'cl-occt:face-area)))))
    (assert-equal 1 (length faces))))

;; ─── Empty query collects all subshapes ───

(deftest query-empty-where-collects-everything
  (let ((results (query-shape (%test-box-shape) :where nil)))
    (assert-equal (+ 6 12 8) (length results))))
