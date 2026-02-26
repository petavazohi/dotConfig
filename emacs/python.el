;;; local python settings ----
;;; Commentary :


;;; Code:
(when (require 'jedi nil 'noerror)
  (setq jedi:complete-on-dot t)
  (setq jedi:environment-root "jedi")
  (add-hook 'python-mode-hook #'jedi:setup))

(with-eval-after-load 'python
  (when (require 'numpydoc nil 'noerror)
    (setq numpydoc-insert-examples-block nil)
    (define-key python-mode-map (kbd "C-S-2") #'numpydoc-generate)))


;; Enable autopep8
(when (require 'py-autopep8 nil 'noerror)
  (with-eval-after-load 'elpy
    (add-hook 'elpy-mode-hook #'py-autopep8-enable-on-save)))

(setq compile-command "python")

;; (elpy-enable)

;; ;; Use IPython for REPL
;; (setq python-shell-interpreter "ipython"
;;       python-shell-interpreter-args "console --simple-prompt"
;;       python-shell-prompt-detect-failure-warning nil)
;; (add-to-list 'python-shell-completion-native-disabled-interpreters
;; 	     "ipython")

;; (add-hook 'python-mode-hook 'python-lsp-mode)

;; (setq yas-triggers-in-field t)
