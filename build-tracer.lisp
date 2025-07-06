;;;
;;; build-tracer.lisp: A Common Lisp module to trace build commands in stages.
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
  (:export #:run-staged-build #:trace-build))

(in-package #:build-tracer)

(defun get-timestamp-string ()
  "Returns a string in YYYYMMDD-HHMMSS format for filenames."
  (multiple-value-bind (second minute hour day month year)
      (get-decoded-time)
    (format nil "~4,'0d~2,'0d~2,'0d-~2,'0d~2,'0d~2,'0d"
            year month day hour minute second)))

(defun run-and-log-command (command args)
  "Executes a single command and logs its stdout and stderr to a file."
  (let* ((timestamp (get-timestamp-string))
         (log-filename (format nil "~a-~a.log" command timestamp))
         (result-plist nil))

    (format t "~&;;; [Stage: ~a] Running command: ~a ~{~a ~}...~%"
            command command args)

    (handler-case
        (multiple-value-bind (stdout stderr exit-code)
            ;; FIX: Use (cons command args) to build the full command list for uiop.
            (uiop:run-program (cons command args)
                              :output :string
                              :error-output :string
                              :ignore-error-status t)

          (with-open-file (log-stream log-filename
                                      :direction :output
                                      :if-exists :supersede)
            ;; FIX: Use command directly, not (first command).
            (format log-stream "--- COMMAND ---~%~a ~{~a ~}~%~%" command args)
            (format log-stream "--- EXIT CODE: ~a ---~%~%" exit-code)
            (format log-stream "--- STDOUT ---~%~a~%~%" stdout)
            (format log-stream "--- STDERR ---~%~a~%" stderr))

          (format t ";;; [Stage: ~a] Complete. Exit Code: ~a. See log: ~a~%"
                  command exit-code log-filename)

          (setf result-plist (list :command command
                                   :log-file log-filename
                                   :exit-code exit-code)))

      (error (c)
        (format t ";;; [Stage: ~a] FAILED TO RUN. Error: ~a~%" command c)
        (setf result-plist (list :command command
                                 :log-file nil
                                 :exit-code -1
                                 :error c))))
    result-plist))

(defun run-staged-build ()
  "Runs the full build process in stages, logging each step."
  (format t "~&;;; --- Starting Staged Build ---~%")
  (let ((stages '(("premake5" "gmake2")
                  ("make" "clean")
                  ("make" "-d")))
        (results '()))
    (dolist (stage stages (reverse results))
      ;; This call is now correct because run-and-log-command is fixed.
      (let ((result (run-and-log-command (first stage) (rest stage))))
        (push result results)
        ;; Stop if a stage fails
        (when (/= (getf result :exit-code) 0)
          (format t ";;; --- Build halted due to non-zero exit code in stage: ~a ---~%" (first stage))
          (return (reverse results)))))))

(defun trace-build (&key (command "make") (args '("-d")))
  "Executes a single build command and captures its output for inspection.
  This is a simpler version that returns output directly to the REPL."
  (format t "~&;;; --- Tracing command: ~a ~{~a ~}---~%" command args)
  (handler-case
      (multiple-value-bind (stdout stderr exit-code)
          (uiop:run-program (cons command args)
                            :output :string
                            :error-output :string
                            :ignore-error-status t)
        (format t "~&;;; --- Trace Complete. Exit Code: ~a ---~%" exit-code)
        (list :stdout stdout
              :stderr stderr
              :exit-code exit-code))
    (error (c)
      (format t "~&;;; --- An error occurred while trying to run the command: ~a ---~%" c)
      (list :stdout ""
            :stderr (format nil "Lisp error: ~a" c)
            :exit-code -1))))

;;; Example Usage from the REPL:
;;;
;;; 1. Load this file:
;;;    * (load "build-tracer.lisp")
;;;
;;; 2. Run the full staged build:
;;;    * (defparameter *build-results* (build-tracer:run-staged-build))
;;;
;;; 3. Inspect the results:
;;;    * (print *build-results*)
;;;    * (getf (first *build-results*) :log-file)
;;;
