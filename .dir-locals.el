;; This file directs emacs to apply these local variable settings
;; to files opened within this project.
;;
;; It includes an alist with items (mode . settings)
;; or (directory . (mode .  ... ))
;; where settings is a list of (variable . value) to set in files of that mode
;; or (eval . expr) to evaluate expr in the context of a file editing buffer.
;; If the mode is nil, the settings are applied to all modes.
;; A directory prefix means to apply the settings only to files in that directory.
;;
;; Unfortunately, there is some clash about what
;; lsp-file-watch-ignored-directories is.  Apparently you have to
;; put the changes inside (with-eval-after-load ...) or the
;; global vs. customized vs. local variable all get scrambled and
;; maybe they're not defined and it's ugly.


((nil . ((eval . (with-eval-after-load 'lsp-mode
                   (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]datasets\\'")
                   (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]ode-strogatz\\'")
                   (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]Things-to-bench\\'")
                   )))))
