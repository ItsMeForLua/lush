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
  (:export #:run-staged-build #:trace-build))

(in-package #:build-tracer)

(defun get-timestamp-string ()
  "Returns a string in YYYYMMDD-HHMMSS format for filenames."
  (multiple-value-bind (second minute hour day month year)
      (get-decoded-time)
    (format nil "~4,'0d~2,'0d~2,'0d-~2,'0d~2,'0d~2,'0d"
            year month day hour minute second)))

(defun diagnose-symbols (symbol-to-find object-files)
  "Uses the 'nm' tool to inspect object files for a given symbol."
  (format t "~&;;; --- Running Symbol Diagnosis ---~%")
  (format t ";;; Searching for symbol '~a' in object files...~%" symbol-to-find)
  (let ((found-in-file nil))
    (dolist (file object-files)
      (when (uiop:file-exists-p file)
        (format t ";;; Inspecting '~a'...~%" file)
        (let ((nm-output (uiop:run-program (list "nm" file) :output :string :ignore-error-status t)))
          ;; We search for the symbol followed by a space to avoid partial matches.
          (if (search (format nil " ~a" symbol-to-find) nm-output)
              (progn
                (setf found-in-file file)
                (format t ";;;   SUCCESS: Found symbol '~a' in ~a.~%" symbol-to-find file)
                ;; Check if it's a global symbol (T) or local/static (t)
                (if (search (format nil " T ~a" symbol-to-find) nm-output)
                    (format t ";;;   INFO: Symbol is GLOBAL (visible to linker).~%")
                    (format t ";;;   WARNING: Symbol is LOCAL (static) and NOT visible to the linker!~%"))
                (return)) ; Stop searching once found
              (format t ";;;   INFO: Symbol '~a' not found in ~a.~%" symbol-to-find file)))))
    (unless found-in-file
      (format t ";;; FAILURE: Symbol '~a' was not found in any of the specified object files.~%" symbol-to-find))
    (format t ";;; --- Symbol Diagnosis Complete ---~%")))

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
  (let ((stages '(("premake5" "gmake2")
                  ("make" "clean")
                  ("make"))) ; Changed from -d to a normal make for clarity
        (results '()))
    (dolist (stage stages (reverse results))
      (let ((result (run-and-log-command (first stage) (rest stage))))
        (push result results)
        (when (/= (getf result :exit-code) 0)
          (format t ";;; --- Build halted due to non-zero exit code in stage: ~a ---~%" (first stage))
          ;; If make fails, run the diagnostics.
          (when (string= (first stage) "make")
            (diagnose-symbols "luaopen_compat53"
                              '("obj/Debug/lush.o" "obj/Debug/compat-5.3.o")))
          (return (reverse results)))))))

;;; Example Usage from the REPL:
;;;
;;; 1. Load this file:
;;;    * (load "build-tracer.lisp")
;;;
;;; 2. Run the full staged build:
;;;    * (build-tracer:run-staged-build)
;;;
