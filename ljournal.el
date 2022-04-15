;; LJournal --- Date-tree oriented LaTex projects
;; Copyright (C) 2022  Jyry "Yrmyjaska" Hjelt

;; Author: Jyry Hjelt <jh2821 (at) ic.ac.uk>
;; Keywords: lisp,latex
;; Version: 1.0.0

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

;; Inspired by blog post: https://castel.dev/post/research-workflow/ .
;; Aims to create a usable interface to create neatly organised LaTeX
;; projects with multiple files and a neat date-tree file structure.

;; Requirements:
;; - yq and jq for YAML parsing
;; - tex (auctex)
;; - f.el

;;; Code:

;; Requirements
(require 'tex)
(require 'f)

;; Configuration options

(defgroup ljournal nil
  "Journalling in LaTeX"
  :group 'tools)

(defcustom ljournal-dateformat "%Y-%m-%d"
  "Date format which to use for creation of new clip files."
  :type 'string
  :group 'ljournal)

(defcustom ljournal-projects nil
  "List of all projects that are under construction by user."
  :type '(repeat directory)
  :group 'ljournal)

(defcustom ljournal-section-filename "section.tex"
  "Name of tex file to be added for each day."
  :type 'string
  :group 'ljournal)

(defcustom ljournal-config-dir nil
  "Where to store skeleton configuration files."
  :type 'directory
  :group 'ljournal)

(defcustom ljournal-default-author ""
  "Default author name for ljournal projects."
  :type 'string
  :group 'ljournal)



;; Main meat of the package

(defun ljournal-add-note ()
  "Create a note for today in specified project."
  (interactive)
  (let
      ((ljournal-chosen-project (completing-read "Choose Project: " ljournal-projects))
       (ljournal-today-date (format-time-string ljournal-dateformat)))
    (ljournal-add-or-modify-note-at-proj ljournal-chosen-project ljournal-today-date)
    ))

(defun ljournal-add-or-modify-note-at-proj (projdir date)
  "Add a note at specified directory named PROJDIR under DATE."
  (let ((dir (concat projdir "/sections/" date))
	(filename (concat projdir "/sections/" date "/" ljournal-section-filename)))
  (progn
      (if (not (file-exists-p projdir))
	  ()
	)
    (if (not (file-exists-p dir))
	(progn
	  (make-directory dir)
	  (write-region (concat "\\section{" date "}\n\n") nil filename)))
    (find-file filename)
    )
   )
  )

(defun ljournal-create-project ()
  "Create a project."
  (interactive)
  (ljournal-create-project-at (read-directory-name "Project location: ") (read-string "Project name: "))
  )

(defun ljournal-create-project-at (path name)
  "Create a project named NAME at PATH."
  (let (
	(preamble-file (concat path "/" "preamble.tex"))
	(preamble-contents (if (file-exists-p (concat ljournal-config-dir "/preamble.tex"))
			       (f-read-text (concat ljournal-config-dir "/preamble.tex"))
			       ""))
	(yaml-file (concat path "/" "metadata.yaml"))
	)
  (progn
    (if (not (file-exists-p path))
	(progn
	  (make-directory path)
	  (make-directory (concat path "/sections"))
	)
      )
    (write-region preamble-contents nil preamble-file)
    (write-region
     (concat "title: " name "\n"
	     "author: " ljournal-default-author "\n"
	     "abstract: \"\"\n")
		  nil yaml-file)
    (cl-pushnew (f-full path) ljournal-projects)
    )
   )
  )

(defun ljournal-get-author (path)
  "Extract author from project located in PATH."
  (shell-command-to-string (concat "eval echo (yq .author " path "/metadata.yaml)"))
  )

(defun ljournal-get-title (path)
  "Extract title from project located in PATH."
  (shell-command-to-string (concat "eval echo (yq .title " path "/metadata.yaml)"))
  )

(defun ljournal-get-abstract (path)
  "Extract abstract from project located in PATH."
  (shell-command-to-string (concat "eval echo (yq .abstract " path "/metadata.yaml)"))
  )

(defun ljournal-make-main ()
  "Compile a chosen lJournal project."
  (interactive)
  (ljournal-make-main-at (completing-read "Choose Project: " ljournal-projects))
  )
(defun ljournal-make-main-at (path)
  "Compile project located at PATH."
  (let (
	(author (ljournal-get-author path))
	(title (ljournal-get-title path))
	(abstract (ljournal-get-abstract path))
	(sections  (nthcdr 2 (directory-files (concat path "/sections"))))
	)
    (progn
      (write-region (concat "\\documentclass[11pt]{article}\n\n"
			    "\n\n"
			    (format "\\title{%s}\n" title)
			    (format "\\author{%s}\n" author)
			    "\\date{\\today}\n\n"
			    "\\input{preamble.tex}\n\n"
			    "\\begin{document}\n"
			    "\\maketitle\n\n"
			    "\\begin{abstract}\n"
			    abstract
			    "\n\\end{abstract}\n"
			    "\\tableofcontents\n\n"
			    (mapconcat
			     (lambda (d) (format "\\input{sections/%s}" (concat d "/" ljournal-section-filename)))
			     sections
			     "\n")
			    "\n\\end{document}\n"
			    )
		    nil
		    (concat path "/main.tex")) ; 
      )
    )
  )

(defun ljournal-locate-project-dir (path)
  "Return the closest project contained from PATH.  Return nil if none found."
  (let ((possible-dir (f-full (locate-dominating-file path "metadata.yaml" ))))
    (if (member possible-dir ljournal-projects)
	possible-dir
      nil)
    )
  )


(defun ljournal-compile-project ()
  "Compile the project located at current working directory.  Fails if not a project directory."
  (interactive)
  (let ((project-dir (f-full (ljournal-locate-project-dir default-directory))))
    (if project-dir
	(progn
	  (ljournal-make-main-at project-dir)
	  (find-file (format "%s/main.tex"  project-dir))
	  (TeX-command-master)
	)
      (message nil))
    )
  )


; TODO: create functions to delete projects.


(provide 'ljournal)

;;; ljournal.el ends here
