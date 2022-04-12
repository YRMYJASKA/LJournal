;; LJournal --- Date-tree oriented LaTex projects
;; Copyright (C) 2022  Jyry "Yrmyjaska" Hjelt

;; Author: Jyry Hjelt <jh2821@ic.ac.uk>
;; Keywords: lisp,latex
;; Version: 0.0.1

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
;; -  yq and jq for YAML parsing

;;; Code:

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

(defcustom ljournal-config-dir "~/.config/ljournal"
  "Where to store skeleton configuration files."
  :type 'directory
  :group 'ljournal)

(defcustom ljournal-default-author ""
  "Default author name for ljournal projects."
  :type 'string
  :group 'ljournal)



;; Creating files
(defun lj-add-note ()
  "Create a note for today in specified project."
  (interactive)
  (let
      ((lj-chosen-project (completing-read "Choose Project: " ljournal-projects))
       (lj-today-date (format-time-string ljournal-dateformat)))
    (lj-add-or-modify-note-at-proj lj-chosen-project lj-today-date)
    ))

(defun lj-add-or-modify-note-at-proj (projdir date)
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

(defun lj-create-project ()
  "Create a project."
  (interactive)
  (lj-create-project-at (read-directory-name "Project location: ") (read-string "Project name: "))
  )

(defun lj-create-project-at (path name)
  "Create a project named NAME at PATH."
  (let (
	(preamble-file (concat path "/" "preamble.tex"))
	(yaml-file (concat path "/" "metadata.yaml"))
	)
  (progn
    (if (not (file-exists-p path))
	(progn
	  (make-directory path)
	  (make-directory (concat path "/sections"))
	)
      )
    (write-region "" nil preamble-file)
    (write-region
     (concat "title: " name "\n"
	     "author: " ljournal-default-author "\n"
	     "abstract: \"\"\n")
		  nil yaml-file)
    (cl-pushnew path ljournal-projects)
    )
   )
  )

(defun lj-get-author (path)
  "Extract author from project located in PATH."
  (shell-command-to-string (concat "eval echo (yq .author " path "/metadata.yaml)"))
  )

(defun lj-get-title (path)
  "Extract title from project located in PATH."
  (shell-command-to-string (concat "eval echo (yq .title " path "/metadata.yaml)"))
  )

(defun lj-get-abstract (path)
  "Extract abstract from project located in PATH."
  (shell-command-to-string (concat "eval echo (yq .abstract " path "/metadata.yaml)"))
  )

(defun lj-make-main ()
  "Compile a chosen lJournal project."
  (interactive)
  (lj-make-main-at (completing-read "Choose Project: " ljournal-projects))
  )
(defun lj-make-main-at (path)
  "Compile project located at PATH."
  (let (
	(author (lj-get-author path))
	(title (lj-get-title path))
	(abstract (lj-get-abstract path))
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
			     (lambda (d) (format "\\subfile{sections/%s}" (concat d "/" ljournal-section-filename)))
			     sections
			     "\n")
			    "\n\\end{document}\n"
			    )
		    nil
		    (concat path "/main.tex")) ; 
      )
    )
  )

(provide 'ljournal)
;;; ljournal.el ends here
