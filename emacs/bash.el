;;; Bash --- commands for sh mode
(add-to-list 'auto-mode-alist '("\\.bashrc.*\\'" . sh-mode))
(add-to-list 'auto-mode-alist '("\\(?:^\\|/\\).*zshrc.*\\'" . sh-mode))
