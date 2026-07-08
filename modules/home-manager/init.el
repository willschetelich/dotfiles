;; MELPA Package Manager
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Install use-package to manage configuration cleanly
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-when-compile (require 'use-package))

;; Turn off noisy file generation 
(setq make-backup-files nil) ;; this gets rid of the '~' files
(setq auto-save-default nil) ;; this disables the # files
(setq create-lockfiles nil)  ;; disables .# in files

;; Modern Auto-Save (Saves the REAL file when you switch focus/stop typing)
(use-package super-save
  :ensure t
  :config
  (super-save-mode +1)
  (setq super-save-auto-save-when-idle t
        super-save-idle-duration 3)) ;; Saves after 3 seconds of idle time

;; Essential UI Cleanup
(setq inhibit-startup-message t) ;; Skip the splash screen
(menu-bar-mode -1)               ;; Hide the top menu bar
(tool-bar-mode -1)               ;; Hide the top icon toolbar
(scroll-bar-mode -1)             ;; Hide the scrollbar for maximum screen space

;; Treemacs: file-tree sidebar on the left (like Doom / VSCode's Explorer)
(use-package treemacs
  :ensure t
  :bind (("<f8>" . treemacs)))    ;; press F8 to toggle the sidebar

;; --- Claude Code IDE -------------------------------------------------------
;; Runs the Claude Code CLI inside Emacs. Requires the `claude` binary on PATH,
;; which is provided by the claude-code package in config/home/home-config.nix.
;; Package home: https://github.com/manzaltu/claude-code-ide.el

;; Terminal backend: vterm (the default) needs native compilation (cmake +
;; libvterm), which is awkward under Nix. `eat` is a pure-Elisp terminal that
;; installs cleanly from MELPA, so we use it instead.
(use-package eat
  :ensure t)

;; websocket: dependency used for the IDE/MCP protocol.
(use-package websocket
  :ensure t)

;; The package isn't on MELPA, so pull it straight from GitHub with :vc
;; (built into use-package on Emacs 29+).
(use-package claude-code-ide
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest)
  :bind ("C-c c" . claude-code-ide-menu)        ;; open the Claude Code menu (terminal-safe; C-c C-' can't be sent in a TTY)
  :init
  (setq claude-code-ide-terminal-backend 'eat) ;; Nix-friendly terminal backend
  :config
  (claude-code-ide-emacs-tools-setup))         ;; enable Emacs <-> Claude tool integration