;; Send SIGUSR1 to the current Lisp process, which triggers the
;; debugger escape handler installed by bootstrap. Any thread stuck
;; in the SBCL debugger will have ABORT invoked on it.
;;
;; Usage from the shell (while ClotCAD is frozen):
;;   slyc --eval '(load "scripts/slyc-debugger-escape.lisp")'
;; or directly:
;;   slyc --eval '(sb-unix:unix-kill (sb-unix:unix-getpid) sb-unix:sigusr1)'
(sb-unix:unix-kill (sb-unix:unix-getpid) sb-unix:sigusr1)
