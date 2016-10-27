;;; lxc-tramp.el --- TRAMP integration for lxc containers  -*- lexical-binding: t; -*-

;; Copyright (C) 2016 Erno Kuusela
;; Copyright (C) 2015 Mario Rodas <marsam@users.noreply.github.com>

;; Authors: Erno Kuusela, Mario Rodas <marsam@users.noreply.github.com>
;; URL: https://github.com/emacs-pe/lxc-tramp.el
;; Keywords: lxc, convenience
;; Version: 0.1
;; Package-Requires: ((emacs "24") (cl-lib "0.5"))

;; This file is NOT part of GNU Emacs.

;;; License:

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
;;
;; `lxc-tramp.el' offers a TRAMP method for LXC containers.
;;
;; > **NOTE**: `lxc-tramp.el' relies in the `lxc exec` command.  Tested
;; > with lxc version 2.0.5 but should work with versions >2.0
;;
;; ## Usage
;;
;; Offers the TRAMP method `lxc` to access running containers
;;
;;     C-x C-f /lxc:user@container:/path/to/file
;;
;;     where
;;       user           is the user that you want to use (optional)
;;       container      is the id or name of the container

;;; Code:
(eval-when-compile (require 'cl-lib))

(require 'tramp)
(require 'tramp-cache)

(defgroup lxc-tramp nil
  "TRAMP integration for Lxc containers."
  :prefix "lxc-tramp-"
  :group 'applications
  :link '(url-link :tag "Github" "https://github.com/erno/lxc-tramp.el")
  :link '(emacs-commentary-link :tag "Commentary" "lxc-tramp"))

(defcustom lxc-tramp-lxc-executable "lxc"
  "Path to lxc executable."
  :type 'string
  :group 'lxc-tramp)

;;;###autoload
(defcustom lxc-tramp-lxc-options nil
  "List of lxc options."
  :type '(repeat string)
  :group 'lxc-tramp)

(defcustom lxc-tramp-use-names nil
  "Whether use names instead of id."
  :type 'boolean
  :group 'lxc-tramp)

;;;###autoload
(defconst lxc-tramp-completion-function-alist
  '((lxc-tramp--parse-running-containers  ""))
  "Default list of (FUNCTION FILE) pairs to be examined for lxc method.")

;;;###autoload
(defconst lxc-tramp-method "lxc"
  "Method to connect lxc containers.")

(defun lxc-tramp--running-containers ()
  "Collect lxc running containers.
Return a list of containers of the form: \(ID NAME\)"
  (cddr  (cl-loop for line in (cdr (ignore-errors (apply #'process-lines lxc-tramp-lxc-executable (append lxc-tramp-lxc-options (list "list" "-c" "cn")))))
                 for info = (split-string line " *| *" t)
                 unless (string-prefix-p "+-" (car info))
                   collect (list (cadr info) (car info)))))

(defun lxc-tramp--parse-running-containers (&optional ignored)
  "Return a list of (user host) tuples.

TRAMP calls this function with a filename which is IGNORED.  The
user is an empty string because the lxc TRAMP method uses bash
to connect to the default user containers."
  (cl-loop for (id name) in (lxc-tramp--running-containers)
           collect (list "" (if lxc-tramp-use-names name id))))

;;;###autoload
(defun lxc-tramp-cleanup ()
  "Cleanup TRAMP cache for lxc method."
  (interactive)
  (let ((containers (apply 'append (lxc-tramp--running-containers))))
    (maphash (lambda (key _)
               (and (vectorp key)
                    (string-equal lxc-tramp-method (tramp-file-name-method key))
                    (not (member (tramp-file-name-host key) containers))
                    (remhash key tramp-cache-data)))
             tramp-cache-data))
  (setq tramp-cache-data-changed t)
  (if (zerop (hash-table-count tramp-cache-data))
      (ignore-errors (delete-file tramp-persistency-file-name))
    (tramp-dump-connection-properties)))

;;;###autoload
(defun lxc-tramp-add-method ()
  "Add lxc tramp method."
  (add-to-list 'tramp-methods
               `(,lxc-tramp-method
                 (tramp-login-program      ,lxc-tramp-lxc-executable)
                 (tramp-login-args         (,lxc-tramp-lxc-options ("exec" "--mode=interactive") ("%h") ("sh")))
                 (tramp-remote-shell       "/bin/sh")
                 (tramp-remote-shell-args  ("-i" "-c")))))

;;;###autoload
(eval-after-load 'tramp
  '(progn
     (lxc-tramp-add-method)
     (tramp-set-completion-function lxc-tramp-method lxc-tramp-completion-function-alist)))

(provide 'lxc-tramp)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; lxc-tramp.el ends here
