;;; test-slang-mode.el --- Test suite for slang-mode

;; Copyright (C) 2024 Free Software Foundation, Inc.

;;; Commentary:

;; Test suite for slang-mode functionality.
;; Tests syntax highlighting, indentation, and basic editing features.

;;; Code:

(require 'ert)
(require 'slang-mode)

;; Helper functions
(defun test-slang-face-at-point (expected-face)
  "Test that the face at point matches EXPECTED-FACE."
  (let ((actual-face (get-text-property (point) 'face)))
    (or (eq actual-face expected-face)
        (and (listp actual-face) (member expected-face actual-face)))))

(defun test-slang-find-and-check-face (text expected-face)
  "Find TEXT in buffer and check it has EXPECTED-FACE."
  (goto-char (point-min))
  (when (search-forward text nil t)
    (backward-char (length text))
    (test-slang-face-at-point expected-face)))

(defmacro test-slang-with-content (content &rest body)
  "Execute BODY in a temporary buffer with CONTENT and slang-mode enabled."
  `(with-temp-buffer
     (insert ,content)
     (slang-mode)
     (font-lock-ensure)
     ,@body))

;; Test mode activation
(ert-deftest test-slang-mode-activation ()
  "Test that slang-mode activates correctly."
  (with-temp-buffer
    (slang-mode)
    (should (eq major-mode 'slang-mode))
    (should (string= mode-name "Slang"))))

;; Test file associations
(ert-deftest test-slang-file-associations ()
  "Test that .slang and .sl files activate slang-mode."
  (let ((slang-file (make-temp-file "test" nil ".slang"))
        (sl-file (make-temp-file "test" nil ".sl"))
        (slang-buf nil)
        (sl-buf nil))
    (unwind-protect
        (progn
          (with-temp-file slang-file
            (insert "float4 test;"))
          (with-temp-file sl-file
            (insert "float4 test;"))
          
          (setq slang-buf (find-file-noselect slang-file))
          (with-current-buffer slang-buf
            (should (eq major-mode 'slang-mode)))
          
          (setq sl-buf (find-file-noselect sl-file))
          (with-current-buffer sl-buf
            (should (eq major-mode 'slang-mode))))
      (progn
        (when slang-buf (kill-buffer slang-buf))
        (when sl-buf (kill-buffer sl-buf))
        (ignore-errors (delete-file slang-file))
        (ignore-errors (delete-file sl-file))))))

;; Test syntax highlighting for keywords
(ert-deftest test-slang-keyword-highlighting ()
  "Test syntax highlighting for Slang keywords."
  (test-slang-with-content 
   "interface ITest { struct Data { enum Type { A, B } } } module Test; import Graphics;"
    (should (test-slang-find-and-check-face "interface" 'font-lock-keyword-face))
    (should (test-slang-find-and-check-face "struct" 'font-lock-keyword-face))
    (should (test-slang-find-and-check-face "enum" 'font-lock-keyword-face))
    (should (test-slang-find-and-check-face "module" 'font-lock-keyword-face))
    (should (test-slang-find-and-check-face "import" 'font-lock-keyword-face))))

;; Test syntax highlighting for types
(ert-deftest test-slang-type-highlighting ()
  "Test syntax highlighting for Slang types."
  (test-slang-with-content
   "float3 pos; float4x4 matrix; Texture2D<float4> tex; StructuredBuffer<Data> buf; uint count; bool flag;"
    (should (test-slang-find-and-check-face "float3" 'font-lock-type-face))
    (should (test-slang-find-and-check-face "float4x4" 'font-lock-type-face))
    (should (test-slang-find-and-check-face "Texture2D" 'font-lock-type-face))
    (should (test-slang-find-and-check-face "StructuredBuffer" 'font-lock-type-face))
    (should (test-slang-find-and-check-face "uint" 'font-lock-type-face))
    (should (test-slang-find-and-check-face "bool" 'font-lock-type-face))))

;; Test syntax highlighting for constants
(ert-deftest test-slang-constant-highlighting ()
  "Test syntax highlighting for Slang constants."
  (test-slang-with-content
   "bool a = true; bool b = false; float4 pos : SV_Position; float3 norm : NORMAL; float2 uv : TEXCOORD0;"
    (should (test-slang-find-and-check-face "true" 'font-lock-constant-face))
    (should (test-slang-find-and-check-face "false" 'font-lock-constant-face))
    (should (test-slang-find-and-check-face "SV_Position" 'font-lock-constant-face))
    (should (test-slang-find-and-check-face "NORMAL" 'font-lock-constant-face))
    (should (test-slang-find-and-check-face "TEXCOORD0" 'font-lock-constant-face))))

;; Test syntax highlighting for built-in functions
(ert-deftest test-slang-function-highlighting ()
  "Test syntax highlighting for Slang built-in functions."
  (test-slang-with-content
   "float x = sin(y); float z = saturate(lerp(a, b, t)); float4 result = mul(vec, matrix); float len = sqrt(dot(v, v)); float c = clamp(val, 0.0f, 1.0f);"
    (should (test-slang-find-and-check-face "sin" 'font-lock-builtin-face))
    (should (test-slang-find-and-check-face "saturate" 'font-lock-builtin-face))
    (should (test-slang-find-and-check-face "lerp" 'font-lock-builtin-face))
    (should (test-slang-find-and-check-face "mul" 'font-lock-builtin-face))
    (should (test-slang-find-and-check-face "sqrt" 'font-lock-builtin-face))
    (should (test-slang-find-and-check-face "clamp" 'font-lock-builtin-face))))

;; Test syntax highlighting for attributes
(ert-deftest test-slang-attribute-highlighting ()
  "Test syntax highlighting for Slang attributes."
  (test-slang-with-content
   "[shader(\"vertex\")] VertexOutput vs() { } [numthreads(8, 8, 1)] void cs() { }"
    (should (test-slang-find-and-check-face "[shader" 'font-lock-preprocessor-face))
    (should (test-slang-find-and-check-face "[numthreads" 'font-lock-preprocessor-face))))

;; Test syntax highlighting for preprocessor directives
(ert-deftest test-slang-preprocessor-highlighting ()
  "Test syntax highlighting for preprocessor directives."
  (test-slang-with-content
   "#define MAX_LIGHTS 32\n#ifdef DEBUG\n#pragma once\n"
    (should (test-slang-find-and-check-face "#define" 'font-lock-preprocessor-face))
    (should (test-slang-find-and-check-face "#ifdef" 'font-lock-preprocessor-face))
    (should (test-slang-find-and-check-face "#pragma" 'font-lock-preprocessor-face))))

;; Test syntax highlighting for comments
(ert-deftest test-slang-comment-highlighting ()
  "Test syntax highlighting for comments."
  (test-slang-with-content
   "// Single line comment\n/* Multi-line\n   comment */\nfloat x;"
    (should (test-slang-find-and-check-face "// Single line comment" 'font-lock-comment-face))
    (should (test-slang-find-and-check-face "/* Multi-line" 'font-lock-comment-face))))

;; Test syntax highlighting for string literals
(ert-deftest test-slang-string-highlighting ()
  "Test syntax highlighting for string literals."
  (test-slang-with-content
   "string message = \"Hello, Slang!\"; char c = 'x';"
    (should (test-slang-find-and-check-face "\"Hello, Slang!\"" 'font-lock-string-face))))

;; Test advanced features highlighting
(ert-deftest test-slang-advanced-highlighting ()
  "Test syntax highlighting for advanced Slang features."
  (test-slang-with-content
   "interface ITest { associatedtype Data; } extension float3 : IComparable { } struct Array<T> where T : IComparable { typealias Iterator = T; property T value { get; set; } __init() { } This getThis() { } expand each T items; }"
    (should (test-slang-find-and-check-face "associatedtype" 'font-lock-keyword-face))
    (should (test-slang-find-and-check-face "where" 'font-lock-keyword-face))
    (should (test-slang-find-and-check-face "extension" 'font-lock-keyword-face))
    (should (test-slang-find-and-check-face "typealias" 'font-lock-keyword-face))
    (should (test-slang-find-and-check-face "property" 'font-lock-keyword-face))
    (should (test-slang-find-and-check-face "__init" 'font-lock-keyword-face))
    (should (test-slang-find-and-check-face "This" 'font-lock-keyword-face))
    (should (test-slang-find-and-check-face "expand" 'font-lock-keyword-face))
    (should (test-slang-find-and-check-face "each" 'font-lock-keyword-face))))

;; Test interface highlighting
(ert-deftest test-slang-interface-highlighting ()
  "Test syntax highlighting for built-in interfaces."
  (test-slang-with-content
   "struct Test : IComparable { } func<T>(x : T) where T : IArithmetic { } float process<T>(T val) where T : IFloat { }"
    (should (test-slang-find-and-check-face "IComparable" 'font-lock-type-face))
    (should (test-slang-find-and-check-face "IArithmetic" 'font-lock-type-face))
    (should (test-slang-find-and-check-face "IFloat" 'font-lock-type-face))))

;; Test comment functionality
(ert-deftest test-slang-comment-functionality ()
  "Test comment/uncomment functionality."
  (with-temp-buffer
    (slang-mode)
    (insert "float test = 1.0f;")
    (goto-char (point-min))
    (comment-line 1)
    (should (string-match-p "^\\s-*//.*float test = 1.0f;" (buffer-string)))
    
    ;; Test uncommenting
    (goto-char (point-min))
    (comment-line 1)
    (should (string-match-p "^\\s-*float test = 1.0f;" (buffer-string)))))

;; Test indentation
(ert-deftest test-slang-indentation ()
  "Test basic indentation functionality."
  (with-temp-buffer
    (slang-mode)
    (insert "struct Test\n{\nfloat value;\n}")
    (goto-char (point-min))
    (forward-line 2)
    (beginning-of-line)
    (c-indent-line)
    (should (looking-at "\\s-+float value;"))))

;; Test electric braces
(ert-deftest test-slang-electric-braces ()
  "Test electric brace functionality."
  (with-temp-buffer
    (slang-mode)
    (insert "struct Test")
    (slang-electric-brace nil)
    (should (looking-back "struct Test{" nil))))

;; Test syntax table
(ert-deftest test-slang-syntax-table ()
  "Test syntax table configuration."
  (with-temp-buffer
    (slang-mode)
    (should (eq (char-syntax ?_) ?w))  ; underscore should be word constituent
    (should (eq (char-syntax ?/) ?.))  ; slash should be punctuation
    (should (eq (char-syntax ?*) ?.))  ; asterisk should be punctuation
    ))

;; Test configuration variables
(ert-deftest test-slang-configuration ()
  "Test mode configuration variables."
  (with-temp-buffer
    (slang-mode)
    (should (string= comment-start "// "))
    (should (string= comment-end ""))
    (should (= c-basic-offset 4))
    (should (= tab-width 4))
    (should (not indent-tabs-mode))
    (should (not case-fold-search))))

;; Run all tests
(defun test-slang-run-all-tests ()
  "Run all slang-mode tests."
  (interactive)
  (message "Running slang-mode test suite...")
  (ert "test-slang-.*")
  (message "slang-mode test suite completed."))

;; Test runner for CI/automated testing
(defun test-slang-batch-run ()
  "Run tests in batch mode for CI."
  (when noninteractive
    (ert-run-tests-batch-and-exit "test-slang-.*")))

(provide 'test-slang-mode)

;;; test-slang-mode.el ends here 