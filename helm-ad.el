;;; helm-ad.el --- helm source for Active Directory

;; Copyright (C) 2014  Takahiro Noda

;; Author: Takahiro Noda <takahiro.noda+github@gmail.com>
;; Created: Jul 31, 2013
;; Version: 0.0.0
;; Keywords: comm
;; Package-Requires: ((dash "2.8.0"))

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

;; helm-ad provides helm sourse and commands for Active Directory's
;; command line utilities, such as gsquery and gsget.

;;; Code:
(require 'cl-lib)
(require 'dash)

(defvar helm-source-ad-action-alist nil)

(unless helm-source-ad-action-alist
  (setq helm-source-ad-action-alist
        `(("user". ("email" "tel" "office"))
          ("contact" . ("email" "tel" "office")))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Helper functions
;;; 
(defun helm-ad-dsget-function (cmd prop)
  (lexical-let ((cmd cmd)
                (prop prop))
    (lambda (dn)
      (with-current-buffer (get-buffer-create "*dsget*")
        (erase-buffer)
        (call-process "dsget" nil t nil
                      cmd
                      (substring dn 1 (1- (length dn)))
                      (concat "-" prop))
        (goto-char (point-min))
        (forward-line)
        (re-search-forward "[^ ]+" nil t)
        (kill-new (match-string-no-properties 0)))
      (insert (car kill-ring)))))

(defun helm-source-ad-command-action (cmd)
  (-map (lambda (prop)
          `(,prop . ,(helm-ad-dsget-function cmd prop)))
        (assoc-default cmd helm-source-ad-action-alist)))

(defun helm-source-ad-command-candidates-function (cmd)
  (lexical-let ((cmd cmd))
    (lambda ()
      (with-temp-buffer
        (call-process "dsquery" nil t nil cmd "-name"
                      (concat helm-pattern "*"))
        (split-string (buffer-string) "\n")))))

(defun helm-source-ad-command (cmd)
  (lexical-let ((cmd cmd))
    `((name . ,(format "Active Directory %s" cmd))
      (candidates . ,(helm-source-ad-command-candidates-function cmd))
      (volatile)
      (requires-pattern . 2)
      (action . ,(helm-source-ad-command-action cmd)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; helm-ad-user
;;;
(defvar helm-source-ad-user (helm-source-ad-command "user"))

(defun helm-ad-user ()
  (interactive)
  (helm-other-buffer '(helm-source-ad-user) "*helm ad user*"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; helm-ad-contact
;;; 
(defvar helm-source-ad-contact (helm-source-ad-command "contact"))

(defun helm-ad-contact ()
  (interactive)
  (helm-other-buffer '(helm-source-ad-contact) "*helm ad contact*"))


;;;###autoload
(defun helm-ad ()
  (interactive)
  (helm-other-buffer '(helm-source-ad-user helm-source-ad-contact)
                     "*helm ad*"))


(provide 'helm-ad)
;;; helm-ad.el ends here
