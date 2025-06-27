;;; test-lsp-integration.el --- Test LSP integration for slang-mode -*- lexical-binding: t; -*-

;;; Commentary:
;; Simple test script to verify that LSP integration is working properly

;;; Code:

(require 'slang-mode)
(require 'slang-lsp)

(defun test-slang-lsp-basic-functionality ()
  "Test basic LSP functionality for slang-mode."
  (interactive)
  (let ((test-buffer "*slang-lsp-test*")
        (test-content "// Test Slang file
module TestModule;

interface ITestInterface {
    float compute(float3 input);
}

struct TestStruct : ITestInterface {
    float3 position;
    float4 color;
    
    float compute(float3 input) {
        return length(input * position);
    }
}

float4 fragmentShader(float3 worldPos) : SV_Target {
    TestStruct test;
    test.position = worldPos;
    test.color = float4(1.0, 0.5, 0.0, 1.0);
    
    float result = test.compute(worldPos);
    return test.color * result;
}"))
    
    (with-current-buffer (get-buffer-create test-buffer)
      (slang-mode)
      (erase-buffer)
      (insert test-content)
      (goto-char (point-min))
      
      (message "Testing slang-mode LSP integration...")
      
      ;; Test 1: Server availability
      (if (slang-lsp-server-available-p)
          (message "✓ slangd server is available")
        (message "✗ slangd server not found"))
      
      ;; Test 2: Server configuration
      (condition-case err
          (progn
            (slang-lsp-setup-server)
            (message "✓ Server configuration successful"))
        (error (message "✗ Server configuration failed: %s" err)))
      
      ;; Test 3: File association
      (if (eq major-mode 'slang-mode)
          (message "✓ slang-mode activated correctly")
        (message "✗ slang-mode not activated"))
      
      ;; Test 4: LSP start (only if server available)
      (when (slang-lsp-server-available-p)
        (condition-case err
            (progn
              (slang-lsp-start)
              (message "✓ LSP server started successfully"))
          (error (message "✗ LSP server start failed: %s" err))))
      
      ;; Display buffer for manual inspection
      (display-buffer test-buffer)
      (message "Test completed. Check buffer %s for syntax highlighting." test-buffer))))

(defun test-slang-lsp-installation-check ()
  "Check if slangd is properly installed and accessible."
  (interactive)
  (message "Checking slangd installation...")
  (message "Search paths: %s" slang-lsp-server-search-paths)
  
  (let ((found-path (slang-lsp--find-server-executable)))
    (if found-path
        (message "✓ slangd found at: %s" found-path)
      (progn
        (message "✗ slangd not found")
        (message "Please install Slang from: https://github.com/shader-slang/slang/releases")
        (message "Or set slang-lsp-server-executable to the correct path"))))
  
  ;; Check if it's executable
  (when-let ((path (slang-lsp--find-server-executable)))
    (if (file-executable-p path)
        (message "✓ slangd is executable")
      (message "✗ slangd found but not executable"))))

(defun test-slang-lsp-server-version ()
  "Try to get slangd server version information."
  (interactive)
  (if-let ((server-path (slang-lsp--find-server-executable)))
      (let ((version-output 
             (shell-command-to-string (format "%s --version" server-path))))
        (if (string-match-p "slang" version-output)
            (message "✓ slangd version: %s" (string-trim version-output))
          (message "? slangd output: %s" (string-trim version-output))))
    (message "✗ slangd not available for version check")))

(defun test-slang-lsp-run-all-tests ()
  "Run all LSP integration tests."
  (interactive)
  (message "=== Slang LSP Integration Test Suite ===")
  (test-slang-lsp-installation-check)
  (message "")
  (test-slang-lsp-server-version)
  (message "")
  (test-slang-lsp-basic-functionality)
  (message "=== Test Suite Complete ==="))

(provide 'test-lsp-integration)

;;; test-lsp-integration.el ends here 