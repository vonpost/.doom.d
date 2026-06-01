;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Daniel Collin"
      user-mail-address "daniel.j.collin@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;;(load-theme 'ewal-doom-vibrant t)
(setq! doom-theme 'doom-dracula)

(defun dcol/disable-other-color-themes (theme)
  (when (or (not (fboundp 'doom--theme-is-colorscheme-p))
            (doom--theme-is-colorscheme-p theme))
    (dolist (enabled (copy-sequence custom-enabled-themes))
      (when (and (not (eq enabled theme))
                 (or (not (fboundp 'doom--theme-is-colorscheme-p))
                     (doom--theme-is-colorscheme-p enabled)))
        (disable-theme enabled)))))

(add-hook 'enable-theme-functions #'dcol/disable-other-color-themes 100)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)


;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
(use-package! frames-only-mode )

;; (use-package! ai-mode-openai
;;   :after (ai-mode ai-model-management)
;;   :config (progn
;;             (add-to-list 'ai-model-management-providers 'ai-mode-openai--get-models)
;;             ;; Set your OpenAI API key:
;;             ;; (setq ai-mode-openai--api-key "YOUR_OPENAI_API_KEY")
;;             ))
(setq frames-only-mode t)
(setq remote-file-name-inhibit-locks t
      tramp-use-scp-direct-remote-copying t
      remote-file-name-inhibit-auto-save-visited t)
(setq remote-file-name-inhibit-locks t
      tramp-use-scp-direct-remote-copying t
      remote-file-name-inhibit-auto-save-visited t)
(with-eval-after-load 'tramp
  (with-eval-after-load 'compile
    (remove-hook 'compilation-mode-hook #'tramp-compile-disable-ssh-controlmaster-options)))
(straight-use-package
 '(ement :type git :host github :repo "alphapapa/ement.el"))
(use-package! msgpack) (use-package! tramp-rpc)
(use-package! detached
  :init
  (detached-init)
  :bind
  (([remap async-shell-command] . detached-shell-command)
   ([remap compile] . detached-compile)
   ([remap recompile] . detached-compile-recompile))
  :config
  (setq detached-show-output-on-attach t))

(use-package! dtach-bootstrap
  :after detached
  :config
  (setq dtach-bootstrap-install-strategies '(system cached nix)
        dtach-bootstrap-detached-missing-action 'prompt)
  (dtach-bootstrap-detached-mode 1))

(defun dcol/ghostel-frame (&optional frame-name)
  "Open a fresh Ghostel terminal in a new frame."
  (interactive)
  (require 'ghostel)
  (dcol/ghostel-frame--open frame-name))

(use-package! ghostel
  :config
  (setq ghostel-query-before-killing nil)

  (defun dcol/ghostel-use-solaire-background (&rest _)
    (when (facep 'ghostel-default)
      (set-face-attribute 'ghostel-default nil
                          :inherit (if (facep 'solaire-default-face)
                                       'solaire-default-face
                                     'default))))

  (defun dcol/ghostel-enable-solaire ()
    (when (fboundp 'solaire-mode)
      (solaire-mode 1)))

  (defun dcol/ghostel-use-corfu-completion ()
    (when (fboundp 'corfu-mode)
      (when (bound-and-true-p corfu-mode)
        (corfu-mode -1))
      (setq-local corfu-auto nil)
      (corfu-mode 1)))

  (defun dcol/ghostel-origin-window ()
    (if (minibufferp)
        (minibuffer-selected-window)
      (selected-window)))

  (defun dcol/ghostel-origin-p ()
    (when-let* ((window (dcol/ghostel-origin-window))
                ((window-live-p window)))
      (with-current-buffer (window-buffer window)
        (derived-mode-p 'ghostel-mode))))

  (defun dcol/ghostel-display-buffer-in-new-frame-p (buffer-name _action)
    (and (dcol/ghostel-origin-p)
         (when-let ((buffer (get-buffer buffer-name)))
           (with-current-buffer buffer
             (not (derived-mode-p 'ghostel-mode))))))

  (defun dcol/ghostel-preserve-terminal-window ()
    (setq-local switch-to-buffer-obey-display-actions t)
    (dolist (window (get-buffer-window-list (current-buffer) nil t))
      (set-window-dedicated-p window t)))

  (defun dcol/ghostel-send-terminal-escape ()
    (interactive)
    (when (fboundp 'ghostel--snap-to-input)
      (ghostel--snap-to-input))
    (ghostel--send-encoded "escape" ""))

  (defun dcol/ghostel-cycle-input-mode ()
    (interactive)
    (pcase ghostel--input-mode
      ('char (ghostel-semi-char-mode))
      ('semi-char (ghostel-line-mode))
      ('line (ghostel-char-mode))
      (_ (ghostel-semi-char-mode))))

  (add-hook 'enable-theme-functions #'dcol/ghostel-use-solaire-background -50)
  (add-hook 'ghostel-mode-hook #'dcol/ghostel-enable-solaire)
  (add-hook 'ghostel-mode-hook #'dcol/ghostel-use-corfu-completion)
  (add-hook 'ghostel-mode-hook #'dcol/ghostel-preserve-terminal-window)
  (dcol/ghostel-use-solaire-background)
  (setq ghostel-keymap-exceptions '("<escape>" "M-x"))
  (ghostel--rebuild-semi-char-keymap)

  (add-to-list 'display-buffer-alist
               '(dcol/ghostel-display-buffer-in-new-frame-p
                 (display-buffer-pop-up-frame)
                 (inhibit-same-window . t)
                 (pop-up-frame-parameters . ((name . "emacs")))))

  (dolist (map (list ghostel-mode-map
                     ghostel-semi-char-mode-map
                     ghostel-char-mode-map
                     ghostel-line-mode-map))
    (define-key map (kbd "M-x") #'execute-extended-command)
    (define-key map (kbd "M-RET") #'dcol/ghostel-cycle-input-mode)
    (define-key map (kbd "M-<return>") #'dcol/ghostel-cycle-input-mode)
    (define-key map (kbd "C-M-m") #'dcol/ghostel-cycle-input-mode))

  (map! :map ghostel-mode-map
        :localleader
        (:prefix ("m" . "mode")
         "c" #'ghostel-char-mode
         "e" #'ghostel-emacs-mode
         "l" #'ghostel-line-mode
         "s" #'ghostel-semi-char-mode
         "y" #'ghostel-copy-mode)
        (:prefix ("s" . "send")
         "\\" #'ghostel-send-C-backslash
         "c" #'ghostel-send-C-c
         "d" #'ghostel-send-C-d
         "e" #'dcol/ghostel-send-terminal-escape
         "g" #'ghostel-send-C-g
         "k" #'ghostel-send-next-key
         "z" #'ghostel-send-C-z)
        "k" #'ghostel-clear-scrollback
        "n" #'ghostel-next-prompt
        "N" #'ghostel-previous-prompt
        "p" #'ghostel-paste
        "y" #'ghostel-copy-all)

  (defun dcol/ghostel-frame-cleanup (frame)
    (when-let* ((buffer (frame-parameter frame 'dcol-ghostel-buffer))
                ((buffer-live-p buffer)))
      (when-let ((proc (get-buffer-process buffer)))
        (set-process-query-on-exit-flag proc nil))
      (let ((kill-buffer-query-functions nil))
        (kill-buffer buffer))))

  (add-hook 'delete-frame-functions #'dcol/ghostel-frame-cleanup)

  (defun dcol/ghostel-frame--open (&optional frame-name)
    "Open a fresh Ghostel terminal in a new frame with minimal overhead."
    (interactive)
    (let* ((terminal-default-directory default-directory)
           (title (or frame-name "ghostel"))
           (after-make-frame-functions
            (remq 'persp-init-new-frame after-make-frame-functions))
           (frame-parameters `((name . ,title)
                               (menu-bar-lines . 0)
                               (tool-bar-lines . 0)
                               (vertical-scroll-bars . nil)
                               (unsplittable . t)))
           (frame (if-let ((display (and (not (display-graphic-p))
                                         (getenv "DISPLAY"))))
                      (make-frame-on-display display frame-parameters)
                    (make-frame frame-parameters)))
           (buffer (generate-new-buffer ghostel-buffer-name)))
      (select-frame frame)
      (set-window-buffer (frame-selected-window frame) buffer)
      (with-current-buffer buffer
        (ghostel--load-module t)
        (ghostel--init-buffer buffer)
        (ghostel-semi-char-mode)
        (dcol/ghostel-enable-solaire)
        (dcol/ghostel-preserve-terminal-window)
        (setq-local default-directory terminal-default-directory
                    ghostel-query-before-killing nil
                    mode-line-format nil
                    frame-title-format title)
        (when (fboundp 'hide-mode-line-mode)
          (hide-mode-line-mode 1))
        (setq ghostel--managed-buffer-name (buffer-name)
              ghostel--buffer-identity (buffer-name))
        (ghostel--start-process)
        (when-let ((proc (get-buffer-process buffer)))
          (set-process-query-on-exit-flag proc nil)))
      (set-frame-parameter frame 'dcol-ghostel-buffer buffer)
      (set-frame-parameter frame 'delete-before nil)
      (set-frame-name title)
      buffer)))
(use-package! evil-ghostel
  :after (ghostel evil)
  :hook (ghostel-mode . evil-ghostel-mode)
  :config
  (setq evil-ghostel-escape 'evil)

  (defvar-local dcol/ghostel-last-escape-time nil)
  (defvar dcol/ghostel-double-escape-delay 0.7)

  (defun dcol/ghostel-insert-escape ()
    (interactive)
    (setq dcol/ghostel-last-escape-time (float-time))
    (evil-force-normal-state))

  (defun dcol/ghostel-normal-escape ()
    (interactive)
    (let ((now (float-time)))
      (if (and dcol/ghostel-last-escape-time
               (< (- now dcol/ghostel-last-escape-time)
                  dcol/ghostel-double-escape-delay))
          (progn
            (setq dcol/ghostel-last-escape-time nil)
            (dcol/ghostel-send-terminal-escape))
        (setq dcol/ghostel-last-escape-time now)
        (keyboard-quit))))

  (defun dcol/ghostel-escape-dwim ()
    (interactive)
    (pcase evil-state
      ('insert (dcol/ghostel-insert-escape))
      ('normal (dcol/ghostel-normal-escape))
      (_ (keyboard-quit))))

  (evil-define-key* 'insert evil-ghostel-mode-map
    (kbd "<escape>") #'dcol/ghostel-insert-escape)
  (evil-define-key* 'normal evil-ghostel-mode-map
    (kbd "<escape>") #'dcol/ghostel-normal-escape)

  (evil-define-key* 'insert ghostel-semi-char-mode-map
    (kbd "C-c") #'ghostel-send-C-c
    (kbd "C-d") #'ghostel-send-C-d)

  (define-key ghostel-semi-char-mode-map (kbd "<escape>")
              #'dcol/ghostel-escape-dwim))
(use-package! hide-mode-line)

(setq tramp-rpc-deploy-git-build-policy 'release)
(use-package! agent-shell)
