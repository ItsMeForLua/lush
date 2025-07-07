;;;
;;; build-tracer.lisp: A Common Lisp module to trace and diagnose C builds.
;;;
;;; To use with Roswell:
;;; 1. Save this file as `build-tracer.lisp`.
;;; 2. Start a Roswell REPL in your project directory: `ros run`
;;; 3. Load the file: `(load "build-tracer.lisp")`
;;; 4. Run the staged build: `(build-tracer:run-staged-build)`
;;;

(require 'uiop)

(defpackage #:build-tracer
  (:use #:cl)
  (:export #:run-staged-build))

(in-package #:build-tracer)

(defun get-timestamp-string ()
  "Returns a string in YYYYMMDD-HHMMSS format for filenames."
  (multiple-value-bind (second minute hour day month year)
      (get-decoded-time)
    (format nil "~4,'0d~2,'0d~2,'0d-~2,'0d~2,'0d~2,'0d"
            year month day hour minute second)))

(defun inspect-source-for-symbol (filepath symbol-name)
  "Reads a C source file and prints the context around a symbol's definition."
  (format t "~&;;; --- Running Source Code Inspection ---~%")
  (format t ";;; Searching for definition of '~a' in '~a'...~%" symbol-name filepath)
  (when (uiop:file-exists-p filepath)
    (handler-case
        (with-open-file (stream filepath)
          (let ((lines (loop for line = (read-line stream nil) while line collect line)))
            (let ((line-number (position-if (lambda (line) (search symbol-name line)) lines)))
              (if line-number
                  (progn
                    (format t ";;;   SUCCESS: Found '~a' at line ~a.~%" symbol-name (1+ line-number))
                    (format t ";;;   Context (10 lines before definition):~%")
                    (format t ";;;   ----------------------------------------~%")
                    (loop for i from (max 0 (- line-number 10)) to line-number
                          do (format t ";;;   ~4d: ~a~%" (1+ i) (nth i lines)))
                    (format t ";;;   ----------------------------------------~%"))
                  (format t ";;;   FAILURE: Could not find a line defining '~a' in the file.~%" symbol-name)))))
      (error (c)
        (format t ";;;   ERROR: Could not read file ~a. Details: ~a~%" filepath c))))
  (format t ";;; --- Source Code Inspection Complete ---~%"))

(defun run-and-log-command (command args)
  "Executes a single command and logs its stdout and stderr to a file."
  (let* ((timestamp (get-timestamp-string))
         (log-filename (format nil "~a-~a.log" command timestamp))
         (result-plist nil))
    (format t "~&;;; [Stage: ~a] Running command: ~a ~{~a ~}...~%" command command args)
    (handler-case
        (multiple-value-bind (stdout stderr exit-code)
            (uiop:run-program (cons command args)
                              :output :string :error-output :string :ignore-error-status t)
          (with-open-file (log-stream log-filename :direction :output :if-exists :supersede)
            (format log-stream "--- COMMAND ---~%~a ~{~a ~}~%~%" command args)
            (format log-stream "--- EXIT CODE: ~a ---~%~%" exit-code)
            (format log-stream "--- STDOUT ---~%~a~%~%" stdout)
            (format log-stream "--- STDERR ---~%~a~%" stderr))
          (format t ";;; [Stage: ~a] Complete. Exit Code: ~a. See log: ~a~%" command exit-code log-filename)
          (setf result-plist (list :command command :log-file log-filename :exit-code exit-code)))
      (error (c)
        (format t ";;; [Stage: ~a] FAILED TO RUN. Error: ~a~%" command c)
        (setf result-plist (list :command command :log-file nil :exit-code -1 :error c))))
    result-plist))

(defun run-staged-build ()
  "Runs the full build process in stages, logging and diagnosing each step."
  (format t "~&;;; --- Starting Staged Build ---~%")
  (let ((stages '(("premake5" "gmake")
                  ("make" "clean")
                  ("make")))
        (results '()))
    (dolist (stage stages (reverse results))
      (let ((result (run-and-log-command (first stage) (rest stage))))
        (push result results)
        (when (/= (getf result :exit-code) 0)
          (format t ";;; --- Build halted due to non-zero exit code in stage: ~a ---~%" (first stage))
          ;; If make fails, run the source code inspection.
          (when (string= (first stage) "make")
            (inspect-source-for-symbol "lib/compat53/c-api/compat-5.3.c" "luaopen_compat53"))
          (return (reverse results)))))))

;;; Example Usage from the REPL:
;;;
;;; 1. Load this file:
;;;    * (load "build-tracer.lisp")
;;;
;;; 2. Run the full staged build:
;;;    * (build-tracer:run-staged-build)
;;;
