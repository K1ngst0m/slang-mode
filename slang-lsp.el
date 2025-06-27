;;; slang-lsp.el --- LSP integration for Slang mode -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Free Software Foundation, Inc.
;;
;; Author: kingstom
;; Keywords: languages, LSP, eglot, slang, shader
;; Version: 1.0
;; Package-Requires: ((emacs "26.1") (eglot "1.4"))

;;; Commentary:

;; This file provides Language Server Protocol (LSP) integration for slang-mode
;; using eglot and the slangd language server.
;;
;; The slangd language server is part of the official Slang compiler toolkit
;; and provides features like:
;; - Real-time diagnostics and error checking
;; - Code completion and IntelliSense
;; - Go-to-definition and find references
;; - Hover documentation
;; - Symbol search

;;; Code:

(require 'eglot)
(require 'slang-mode)

(defgroup slang-lsp nil
  "LSP integration for Slang mode."
  :group 'slang
  :prefix "slang-lsp-")

(defcustom slang-lsp-server-executable "slangd"
  "Path to the slangd language server executable.
Can be either a full path or just the executable name if it's in PATH."
  :type 'string
  :group 'slang-lsp)

(defcustom slang-lsp-server-args '()
  "Additional arguments to pass to the slangd server."
  :type '(repeat string)
  :group 'slang-lsp)

(defcustom slang-lsp-auto-enable t
  "Whether to automatically enable LSP when opening Slang files."
  :type 'boolean
  :group 'slang-lsp)

(defcustom slang-lsp-server-search-paths
  '("/usr/local/bin"
    "/usr/bin"
    "~/.local/bin"
    "~/bin"
    "/opt/slang/bin")
  "Paths to search for slangd executable."
  :type '(repeat directory)
  :group 'slang-lsp)

(defun slang-lsp--find-server-executable ()
  "Find the slangd executable in the system.
Returns the full path to slangd if found, nil otherwise."
  (or
   ;; Check if custom executable path is valid
   (when (and slang-lsp-server-executable
              (not (string= slang-lsp-server-executable "slangd"))
              (file-executable-p slang-lsp-server-executable))
     slang-lsp-server-executable)
   
   ;; Check if slangd is in PATH
   (executable-find "slangd")
   
   ;; Search in common installation paths
   (cl-some (lambda (path)
              (let ((full-path (expand-file-name "slangd" path)))
                (when (file-executable-p full-path)
                  full-path)))
            slang-lsp-server-search-paths)))

(defun slang-lsp-server-available-p ()
  "Check if slangd server is available on the system."
  (not (null (slang-lsp--find-server-executable))))

(defun slang-lsp-setup-server ()
  "Configure eglot to use slangd for Slang files."
  (let ((server-path (slang-lsp--find-server-executable)))
    (if server-path
        (progn
          (add-to-list 'eglot-server-programs
                       `((slang-mode) . (,server-path ,@slang-lsp-server-args)))
          (message "Slang LSP: configured slangd server at %s" server-path))
      (message "Slang LSP: slangd server not found. Please install Slang compiler or set slang-lsp-server-executable."))))

(defun slang-lsp-start ()
  "Start LSP server for current Slang buffer."
  (interactive)
  (if (slang-lsp-server-available-p)
      (eglot-ensure)
    (user-error "slangd server not available. Please install Slang compiler")))

(defun slang-lsp-restart ()
  "Restart LSP server for current Slang buffer."
  (interactive)
  (when (eglot-current-server)
    (eglot-shutdown (eglot-current-server)))
  (slang-lsp-start))

(defun slang-lsp-stop ()
  "Stop LSP server for current buffer."
  (interactive)
  (when (eglot-current-server)
    (eglot-shutdown (eglot-current-server))))

(defun slang-lsp-show-server-info ()
  "Display information about the current LSP server."
  (interactive)
  (if-let ((server (eglot-current-server)))
      (message "Slang LSP: Server running at %s (PID: %s)"
               (eglot--server-capable-or-lose server :serverInfo :name "Unknown")
               (process-id (eglot--process server)))
    (message "Slang LSP: No server running for this buffer")))

(defun slang-lsp-update-configuration ()
  "Send updated workspace configuration to the language server."
  (interactive)
  (if-let ((server (eglot-current-server)))
      (progn
        (slang-lsp--setup-workspace-configuration)
        (eglot-signal-didChangeConfiguration server)
        (message "Slang LSP: Configuration updated"))
    (message "Slang LSP: No server running for this buffer")))

;; Enhanced mode configuration
(defun slang-lsp-configure-buffer ()
  "Configure current buffer for optimal LSP experience."
  (when (derived-mode-p 'slang-mode)
    ;; Enable common LSP features
    (setq-local eldoc-documentation-strategy 'eldoc-documentation-compose-eagerly)
    
    ;; Configure completion (use what's available)
    (if (fboundp 'cape-dabbrev)
        (setq-local completion-at-point-functions
                    (list #'eglot-completion-at-point
                          #'cape-dabbrev
                          #'cape-file))
      (setq-local completion-at-point-functions
                  (list #'eglot-completion-at-point
                        #'dabbrev-completion)))
    
    ;; Set up keybindings - only use capabilities that slangd actually supports
    (local-set-key (kbd "C-c l d") #'xref-find-definitions)  ; Uses definitionProvider
    ;; Note: slangd doesn't support referencesProvider, implementationProvider, or typeDefinitionProvider
    ;; so we don't bind those keys to avoid errors
    (local-set-key (kbd "C-c l n") #'eglot-rename)
    (local-set-key (kbd "C-c l f") #'eglot-format)
    (local-set-key (kbd "C-c l a") #'eglot-code-actions)
    (local-set-key (kbd "C-c l h") #'eldoc)
    (local-set-key (kbd "C-c l s") #'slang-lsp-show-server-info)
    (local-set-key (kbd "C-c l R") #'slang-lsp-restart)
    (local-set-key (kbd "C-c l c") #'slang-lsp-update-configuration)))

;; Auto-enable hook
(defun slang-lsp-auto-enable ()
  "Automatically enable LSP for Slang files if configured."
  (when (and slang-lsp-auto-enable
             (slang-lsp-server-available-p))
    (slang-lsp-start)
    (slang-lsp-configure-buffer)))

;; Initialization function
(defun slang-lsp-initialize ()
  "Initialize Slang LSP integration."
  (slang-lsp-setup-server)
  
  ;; Add hook for auto-enabling LSP
  (add-hook 'slang-mode-hook #'slang-lsp-auto-enable)
  
  ;; Configure eglot for better Slang support
  (with-eval-after-load 'eglot
    ;; Slang-specific server configuration
    (add-to-list 'eglot-stay-out-of 'flymake) ; Use eglot's diagnostics
    
    ;; Enhanced diagnostics display
    (setq eglot-events-buffer-size 0) ; Disable events buffer for performance
    (setq eglot-autoshutdown t) ; Auto-shutdown when last buffer is closed
    
    ;; Optional: Log when LSP connects successfully
    (add-hook 'eglot-managed-mode-hook
              (lambda ()
                (when (derived-mode-p 'slang-mode)
                  (message "Slang LSP: Connected successfully"))))
    
    ;; Define workspace configuration for Slang LSP
    (defun slang-lsp--workspace-configuration (server)
      "Return workspace configuration for Slang Language Server."
      (list :slang (list :completion (list :enableSnippets t
                                          :enableAutoImport t)
                        :diagnostics (list :enableExperimental t)
                        :formatting (list :enable t)
                        :hover (list :enable t)
                        :semanticTokens (list :enable t)
                        :inlayHints (list :enable t))))

    
    ;; Set up workspace configuration for slang-mode buffers
    (defun slang-lsp--setup-workspace-configuration ()
      "Set up workspace configuration for current slang buffer."
      (setq-local eglot-workspace-configuration
                  (slang-lsp--workspace-configuration nil)))
    
    ;; Hook to set up workspace configuration when LSP starts
    (add-hook 'eglot-managed-mode-hook
              (lambda ()
                (when (derived-mode-p 'slang-mode)
                  (slang-lsp--setup-workspace-configuration))))
    ))

;; Interactive commands for menu
(defun slang-lsp-install-guide ()
  "Show installation guide for slangd."
  (interactive)
  (message "To install slangd LSP server: 1) Download Slang from https://github.com/shader-slang/slang/releases 2) Extract slangd executable from bin/ directory 3) Add to PATH or set slang-lsp-server-executable 4) Restart Emacs. NOTE: The slangd from Vulkan SDK is NOT the LSP server!"))

(defun slang-lsp-check-server-type ()
  "Check if the current slangd is the correct LSP server."
  (interactive)
  (let ((server-path (slang-lsp--find-server-executable)))
    (if server-path
        (message "✓ Found slangd at: %s (with LSP symbols based on your analysis)" server-path)
      (message "No slangd executable found. Download from https://github.com/shader-slang/slang/releases"))))

(defun slang-lsp-test-server-manual ()
  "Manually test the slangd server connection."
  (interactive)
  (let ((server-path (slang-lsp--find-server-executable)))
    (if server-path
        (let* ((buffer-name "*slangd-test*")
               (process (start-process "slangd-test" buffer-name server-path)))
          (set-process-query-on-exit-flag process nil)
          (message "Started slangd test process. Check buffer: %s" buffer-name)
          ;; Send a simple LSP initialize request
          (run-with-timer 1 nil
            (lambda ()
              (when (process-live-p process)
                (process-send-string process 
                  "Content-Length: 122\r\n\r\n{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"capabilities\":{},\"processId\":null}}\n")
                (message "Sent initialize request to slangd"))))
          ;; Kill after 5 seconds
          (run-with-timer 5 nil
            (lambda ()
              (when (process-live-p process)
                (kill-process process)
                (message "Killed slangd test process")))))
      (message "No slangd executable found"))))

(defun slang-lsp-debug-capabilities ()
  "Debug function to show what capabilities the LSP server supports."
  (interactive)
  (if-let ((server (eglot-current-server)))
      (let ((caps (eglot--capabilities server)))
        (with-current-buffer (get-buffer-create "*Slang LSP Debug*")
          (erase-buffer)
          (insert "=== Slang LSP Server Capabilities ===\n\n")
          (insert (format "Full capabilities object:\n%S\n\n" caps))
          (insert "Specific capability checks:\n")
          (insert (format "definitionProvider: %S\n" (eglot-server-capable :definitionProvider)))
          (insert (format "referencesProvider: %S\n" (eglot-server-capable :referencesProvider)))
          (insert (format "implementationProvider: %S\n" (eglot-server-capable :implementationProvider)))
          (insert (format "typeDefinitionProvider: %S\n" (eglot-server-capable :typeDefinitionProvider)))
          (insert (format "declarationProvider: %S\n" (eglot-server-capable :declarationProvider)))
          (pop-to-buffer (current-buffer))))
    (message "No LSP server running")))

;; Add menu items to slang-mode
(with-eval-after-load 'slang-mode
  (easy-menu-add-item slang-mode-menu nil
    '("LSP"
      ["Start LSP" slang-lsp-start :enable (not (eglot-current-server))]
      ["Stop LSP" slang-lsp-stop :enable (eglot-current-server)]
      ["Restart LSP" slang-lsp-restart :enable (eglot-current-server)]
      "---"
      ["Find Definition" xref-find-definitions :enable (eglot-current-server)]
      ;; Note: References, Implementation, Type Definition not supported by this slangd version
      ["Rename Symbol" eglot-rename :enable (eglot-current-server)]
      ["Format Buffer" eglot-format :enable (eglot-current-server)]
      ["Code Actions" eglot-code-actions :enable (eglot-current-server)]
      "---"
      ["Update Configuration" slang-lsp-update-configuration :enable (eglot-current-server)]
      ["Server Info" slang-lsp-show-server-info :enable (eglot-current-server)]
      ["Debug Capabilities" slang-lsp-debug-capabilities :enable (eglot-current-server)]
      ["Check Server Type" slang-lsp-check-server-type t]
      ["Test Server Manual" slang-lsp-test-server-manual t]
      ["Installation Guide" slang-lsp-install-guide t])))

(provide 'slang-lsp)

;;; slang-lsp.el ends here 