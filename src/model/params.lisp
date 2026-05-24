(in-package :clotcad.impl)

(defvar *params* nil
  "Global parameter plist for parametric models.")

(defvar *local-params* nil
  "Local parameter plist, bound by with-params.")

(defvar *after-propagation-hook* nil
  "List of functions called after each propagate-changes.")
