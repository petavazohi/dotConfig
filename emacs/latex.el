(auctex-latexmk-setup)
(latex-preview-pane-enable)
(setq TeX-PDF-mode t)


;;; AUCTeX

;; spell check
(add-hook 'TeX-mode-hook 'flyspell-mode)

;; support \ref{} and \cite{}
(add-hook 'TeX-mode-hook 'turn-on-reftex)


(setq TeX-engine 'luatex)

(with-eval-after-load 'tex
  (add-to-list 'TeX-command-list
               '("LuaLaTeX" "%`lualatex%(mode) %t" TeX-run-TeX nil t)
               t))
