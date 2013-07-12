;;; emamux-ruby-test.el --- Ruby test with emamux

;; Copyright (C) 2013 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emamux-ruby-test
;; Package-Requires: ((emamux "0.01") (projectile "0.9.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; emamux-ruby-test makes you test ruby file with emamux.
;; This package is inspired by vimux-ruby-test.
;;
;; To use emamux-ruby-test, add the following code into your init.el or .emacs:
;;
;;    (require 'emamux-ruby-test)
;;    (global-emamux-ruby-test-mode)
;;
;; To use emamux-ruby-test with specific mode only, add folowing:
;;
;;    (require 'emamux-ruby-test)
;;    (add-hook 'ruby-mode-hook 'emamux-ruby-test-mode)
;;
;; emamux-ruby-test provides following commands:
;;
;; Run all tests/specs in the current project
;;     M-x emamux-ruby-test:run-all
;;
;; Run all tests/specs in the current file
;;     M-x emamux-ruby-test:run-current-test
;;
;; Load ruby console dependent of current project type
;;     M-x emamux-ruby-test:run-console
;;

;;; Code:

(require 'emamux)
(require 'projectile)

(defgroup emamux-ruby-test nil
  "Ruby test with emamux"
  :group 'tools)

(defcustom emamux-ruby-test-keymap-prefix (kbd "C-c r")
  "Keymap prefix for emamux-ruby-test mode."
  :group 'emamux-ruby-test
  :type 'string)

(defcustom emamux-ruby-test-mode-lighter " Test"
  "Lighter used in emamux-ruby-test-mode."
  :group 'emamux-ruby-test
  :type 'string)


;;; Utility functions.

(defun emamux-rt:project-root ()
  "Absolute path to ruby project."
  (let ((projectile-require-project-root t))
    (ignore-errors
      (projectile-project-root))))

(defun emamux-rt:project-type ()
  "Ruby project type specification."
  (let ((projectile-require-project-root t))
    (ignore-errors
      (projectile-project-type))))

(defun emamux-rt:source-file-p (file)
  "Return t if FILE is a ruby source."
  (and file
       (file-regular-p file)
       (s-ends-with? ".rb" file)))

(defun emamux-rt:project-p ()
  "Return t if PROJ is a ruby language project."
  (or (emamux-rt:rails-project-p)
      (emamux-rt:ruby-project-p)))

(defun emamux-rt:rails-project-p ()
  "Return t if PROJ is a rails framework project."
  (s-starts-with? "rails" (symbol-name (emamux-rt:project-type))))

(defun emamux-rt:ruby-project-p ()
  "Return t if PROJ is a rails framework project."
  (s-starts-with? "ruby" (symbol-name (emamux-rt:project-type))))

(defun emamux-rt:test-unit-p ()
  "Return t if PROJ is a rails framework project."
  (s-ends-with? "test" (symbol-name (emamux-rt:project-type))))

(defun emamux-rt:rspec-p ()
  "Return t if PROJ is a rails framework project."
  (s-ends-with? "rspec" (symbol-name (emamux-rt:project-type))))

(defun emamux-rt:relative-file-name (file)
  "Return relative path name for FILE."
  (substring file (length (emamux-rt:project-root))))

(defun emamux-rt:relative-test-name (file)
  "Return relative test name for FILE."
  (if (projectile-test-file-p file)
      (emamux-rt:relative-file-name file)
    (or (projectile-find-matching-test file)
        (error "No corresponding test/spec found"))))


;;; Projects functions.

(defun emamux-rt:test-command ()
  "Return command to test whole project"
  (projectile-test-command (emamux-rt:project-root)))

(defun emamux-rt:console-command ()
  "Return command appropriate to start project console."
  (cond
   ((emamux-rt:rails-project-p)
    "bundle exec rails console")
   ((emamux-rt:ruby-project-p)
    "bundle console")
   (t
    (error "No console type found"))))

(defun emamux-rt:current-test-pattern ()
  "Return string appropriate for formatting current test command."
  (cond
   ((emamux-rt:rspec-p)
    "bundle exec rspec %s")
   ((emamux-rt:test-unit-p)
    "bundle exec rake test TEST=%s")
   (t
    (error "No test engine found"))))


;;; Runner functions.

(defun emamux-ruby-test:run-all ()
  "Run all tests/specs in the current project."
  (interactive)
  (emamux:run-command
   (emamux-rt:test-command)
   (emamux-rt:project-root)))

(defun emamux-ruby-test:run-console ()
  "Load ruby console dependent of current project type."
  (interactive)
  (emamux:run-command
   (emamux-rt:console-command)
   (emamux-rt:project-root)))

(defun emamux-ruby-test:run-current-test ()
  "Run all tests/specs in the current file."
  (interactive)
  (let ((file (buffer-file-name)))
    (if (not (emamux-rt:source-file-p file))
        (error "Can't find current test")
      (emamux:run-command
       (format
        (emamux-rt:current-test-pattern)
        (emamux-rt:relative-test-name file))
       (emamux-rt:project-root)))))


;;; Minor mode definition.

(defvar emamux-ruby-test-mode-map
  (let ((map (make-sparse-keymap)))
    (let ((prefix-map (make-sparse-keymap)))
      (define-key prefix-map (kbd "T") 'emamux-ruby-test:run-all)
      (define-key prefix-map (kbd "c") 'emamux-ruby-test:run-console)
      (define-key prefix-map (kbd "t") 'emamux-ruby-test:run-current-test)
      (define-key prefix-map (kbd "k") 'emamux:close-runner-pane)
      (define-key prefix-map (kbd "r") 'emamux:inspect-runner)

      (define-key map emamux-ruby-test-keymap-prefix prefix-map))
    map)
  "Keymap for emamux-ruby-test mode.")

;;;###autoload

(define-minor-mode emamux-ruby-test-mode
  "Minor mode to Ruby test with emamux.

\\{emamux-ruby-test-mode-map}"
  :lighter emamux-ruby-test-mode-lighter
  :keymap emamux-ruby-test-mode-map
  :group 'emamux-ruby-test)

(define-globalized-minor-mode global-emamux-ruby-test-mode
  emamux-ruby-test-mode
  emamux-ruby-test-on)

(defun emamux-ruby-test-on ()
  "Enable emamux-ruby-test minor mode only if current buffer is a part of ruby project."
  (when (emamux-rt:project-p)
    (emamux-ruby-test-mode 1)))

(defun emamux-ruby-test-off ()
  "Disable emamux-ruby-test minor mode."
  (emamux-ruby-test-mode -1))

(provide 'emamux-ruby-test)

;;; emamux-ruby-test.el ends here
