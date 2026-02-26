;; Fortran comment mode change to !
(add-to-list 'auto-mode-alist '("\\.f\\'" . f90-mode))
(add-to-list 'auto-mode-alist '("\\.F\\'" . f90-mode))
(add-hook 'f90-mode-hook
          ;; These are the default values.
          (lambda ()
            (setq f90-do-indent 3
                  f90-if-indent 3
                  f90-type-indent 3
                  f90-program-indent 2
                  f90-continuation-indent 5
                  f90-comment-region "!"
                  f90-directive-comment-re "!hpf\\$"
                  f90-indented-comment-re "!"
                  f90-break-delimiters "[-+\\*/><=,% \t]"
                  f90-break-before-delimiters t
                  f90-beginning-ampersand t
                  f90-smart-end 'blink
                  f90-auto-keyword-case nil
                  f90-leave-line-no nil
                  indent-tabs-mode nil
                  f90-font-lock-keywords f90-font-lock-keywords-2)))
