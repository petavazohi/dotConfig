;;; init.el --- Simplified and Organized Emacs Configuration

;;; Host Profile (light/full)
(defun my/system-memory-kb ()
  "Return total system memory in KB when available, otherwise nil."
  (when (file-readable-p "/proc/meminfo")
    (with-temp-buffer
      (insert-file-contents "/proc/meminfo")
      (when (re-search-forward "^MemTotal:[[:space:]]+\\([0-9]+\\)[[:space:]]+kB" nil t)
        (string-to-number (match-string 1))))))

(defconst my/light-profile
  (let* ((env (getenv "EMACS_LIGHT"))
         (mem-kb (my/system-memory-kb)))
    (or (and env (member (downcase env) '("1" "true" "yes" "on")))
        (and mem-kb (< mem-kb 900000))))
  "When non-nil, use a lightweight Emacs profile for low-memory hosts.")

;; Package Management Setup
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("gnu" . "https://elpa.gnu.org/packages/")))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)
(setq use-package-always-defer t)

;; Package List
;; Install and configure packages with use-package
(use-package flyspell :ensure nil :defer nil)
(use-package markdown-mode
  :mode ("\\.md\\'" "\\.markdown\\'"))
(use-package org
  :ensure nil
  :defer t)
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))
(use-package web-mode
  :mode ("\\.html?\\'" "\\.jsx\\'" "\\.tsx?\\'"))
(use-package windmove
  :ensure nil
  :defer t)
(use-package yaml-mode
  :mode ("\\.yml\\'" "\\.yaml\\'"))
(use-package apache-mode
  :mode (("\\.htaccess\\'" . apache-mode)
         ("httpd\\.conf\\'" . apache-mode)
         ("apache2\\.conf\\'" . apache-mode)
         ("sites-\\(?:available\\|enabled\\)/.*\\'" . apache-mode)))
(use-package material-theme :defer t)
(use-package eglot :ensure nil)

(unless my/light-profile
  (use-package tex
    :defer nil
    :ensure auctex
    :config
    (setq TeX-auto-save t))
  (use-package auctex-latexmk
    :after tex
    :config
    (auctex-latexmk-setup)))


;;; User Information
(setq user-full-name "Pedram Tavadze"
      user-mail-address "petavazohi@gmail.com")

;;; Performance Tuning
(setq gc-cons-threshold 50000000)
(setq large-file-warning-threshold 100000000)
(message "Emacs startup profile: %s" (if my/light-profile "light" "full"))
(add-hook 'emacs-startup-hook
          (lambda ()
            (message "Init: %.2fs, GC: %d"
                     (float-time (time-subtract after-init-time before-init-time))
                     gcs-done)))

;;; UI Tweaks
(tool-bar-mode -1)
(setq require-final-newline t)
(delete-selection-mode t)
;; (global-linum-mode t)
;; (setq linum-format "%4d \u2502 ")
;; (global-display-line-numbers-mode t)
(if (>= emacs-major-version 29)
    (global-display-line-numbers-mode t)
  (global-linum-mode t))
(condition-case nil
    (load-theme 'material t)
  (error
   (load-theme 'tango-dark t)))

;;; Editing Enhancements
(electric-pair-mode 1)
(show-paren-mode 1)
(global-hl-line-mode 1)
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

;;; Load External Files and Mode-Specific Configurations
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file t)
(load "~/.emacs.d/local" t)
(load "~/.emacs.d/bash" t)

(unless my/light-profile
  (add-hook 'latex-mode-hook (lambda () (load "~/.emacs.d/latex" t)))
  (load "~/.emacs.d/f90" t)
  (load "~/.emacs.d/vasp-mode" t)
  (add-to-list 'auto-mode-alist '("\\(?:^\\|/\\)[^/]*CAR\\'" . vasp-mode))
  (dolist (vasp-file '("INCAR" "POSCAR" "POTCAR" "CONTCAR" "KPOINTS" "OUTCAR"))
    (add-to-list 'auto-mode-alist
                 (cons (format "\\(?:^\\|/\\)%s\\(?:\\..*\\)?\\'" vasp-file)
                       'vasp-mode)))
  (add-hook 'python-mode-hook (lambda () (load "~/.emacs.d/python" t))))

;;; Custom Function Definitions
(defun comment-or-uncomment-region-or-line ()
  "Comments or uncomments the region or the current line if no region is selected."
  (interactive)
  (let ((start (line-beginning-position))
        (end (line-end-position)))
    (when (region-active-p)
      (setq start (region-beginning) end (region-end)))
    (comment-or-uncomment-region start end)))

;;; Keybindings
;; for emacs C-/ is sent to C-_ so for C-/ to work we need to bind it with C-_
(global-set-key (kbd "C-_") 'comment-or-uncomment-region-or-line)

(global-set-key (kbd "<f5>") 'compile)
(global-set-key (kbd "<f6>") 'recompile)

(global-set-key (kbd "C-<left>")  'windmove-left)
(global-set-key (kbd "C-<right>") 'windmove-right)
(global-set-key (kbd "C-<up>")    'windmove-up)
(global-set-key (kbd "C-<down>")  'windmove-down)


(global-set-key (kbd "C-<prior>") 'previous-buffer)
(global-set-key (kbd "C-<next>") 'next-buffer)


(global-set-key (kbd "C-a") 'mark-whole-buffer)

(global-set-key (kbd "C-l") 'display-line-numbers-mode)
(global-set-key (kbd "C-q") 'display-fill-column-indicator-mode)
;; (global-set-key (kbd "C-w") 'kill-buffer)
(global-set-key (kbd "C-o") 'find-file)
;; (global-set-key (kbd "C-x \\\"") 'split-window-below)
;; (global-set-key (kbd "C-x %") 'split-window-right)
;; (global-set-key (kbd "C-x -") 'split-window-below)
;; (global-set-key (kbd "C-x _") 'split-window-right)
;; (global-set-key (kbd "C-g")  'flycheck-list-errors)

;; Add more keybindings as needed...

;;; Additional Settings and Hooks
;; Do not create backup/auto-save/lock files (no ~, #...#, or .#...).
(setq make-backup-files nil
      auto-save-default nil
      create-lockfiles nil
      auto-save-list-file-prefix nil)

(add-hook 'text-mode-hook 'flyspell-mode)
(add-hook 'prog-mode-hook 'flyspell-prog-mode)

;;; init.el ends here
