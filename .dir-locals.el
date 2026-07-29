;; This file directs emacs to apply these local variable settings
;; to files opened within this project.
;;
;; It includes a list of pairs (mode . settings)
;; or (directory . (mode .  ... ))
;; where settings is a list of (variable . value) to set in files of that mode
;; or (eval . expr) to evaluate expr in the context of a file editing buffer.
;; If the mode is nil, the settings are applied to all modes.
;; A directory prefix means to apply the settings only to files in that directory.

((nil . ((eval . (setq-local lsp-file-watch-ignored-directories
                             (append lsp-file-watch-ignored-directories
                                     '("[/\\\\]datasets\\'"
                                       "[/\\\\]ode-strogatz\\'"
                                       "[/\\\\]Things-to-bench\\'")))))))
