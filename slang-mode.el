;;; slang-mode.el --- Major mode for Slang shader files

;; Copyright (C) 2024 Free Software Foundation, Inc.
;;
;; Author: kingstom
;; Keywords: languages, Slang, shader, graphics
;; Version: 1.0
;; Package-Requires: ((emacs "24.3"))

;; This file is part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This package provides a major mode for editing Slang shader language files.
;; Slang is a shading language developed by NVIDIA that brings modern language
;; features to GPU programming including generics, interfaces, and modules.
;;
;; Features provided:
;; - Comprehensive syntax highlighting for Slang keywords, types, and constructs
;; - Proper indentation based on C-mode
;; - Comment handling for both single-line (//) and multi-line (/* */) comments
;; - Electric brace insertion
;; - Imenu support for navigating functions and types
;; - File associations for .slang and .sl extensions

;;; Code:

(require 'cc-mode)
(require 'font-lock)

(defgroup slang nil
  "Major mode for editing Slang shader files."
  :group 'languages
  :prefix "slang-")

(defcustom slang-indent-offset 4
  "Indentation offset for Slang code."
  :type 'integer
  :group 'slang)

;; Syntax table
(defvar slang-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; C-style comments
    (modify-syntax-entry ?/ ". 124b" table)
    (modify-syntax-entry ?* ". 23" table)
    (modify-syntax-entry ?\n "> b" table)
    
    ;; Strings
    (modify-syntax-entry ?\" "\"" table)
    (modify-syntax-entry ?\' "\"" table)
    
    ;; Operators and punctuation
    (modify-syntax-entry ?+ "." table)
    (modify-syntax-entry ?- "." table)
    (modify-syntax-entry ?% "." table)
    (modify-syntax-entry ?< "." table)
    (modify-syntax-entry ?> "." table)
    (modify-syntax-entry ?& "." table)
    (modify-syntax-entry ?| "." table)
    (modify-syntax-entry ?= "." table)
    (modify-syntax-entry ?! "." table)
    
    ;; Underscore as word constituent
    (modify-syntax-entry ?_ "w" table)
    
    table)
  "Syntax table for Slang mode.")

;; Font lock keywords - comprehensive Slang language support
(defconst slang-font-lock-keywords
  (list
   ;; Preprocessor directives
   '("^[ \t]*#.*$" . 'font-lock-preprocessor-face)
   
   ;; Attributes (shader annotations)
   '("\\[\\([^]]+\\)\\]" . 'font-lock-preprocessor-face)
   
   ;; Keywords - core language
   `(,(regexp-opt '("break" "case" "continue" "default" "do" "else" "for" 
                    "if" "return" "switch" "while" "goto"
                    "const" "static" "uniform" "varying" "in" "out" "inout"
                    "public" "private" "internal" "extern"
                    "true" "false" "null" "none")
                  'words)
     . 'font-lock-keyword-face)
   
   ;; Keywords - Slang-specific
   `(,(regexp-opt '("interface" "struct" "enum" "class" "namespace" "module"
                    "import" "export" "using" "typealias" "associatedtype"
                    "extension" "where" "let" "var" "property" "subscript"
                    "init" "__init" "deinit" "__deinit" "this" "This" "Self"
                    "super" "throws" "try" "catch" "finally"
                    "is" "as" "sizeof" "alignof" "offsetof"
                    "expand" "each" "repeat" "unroll" "loop"
                    "target" "version" "profile" "stage" "binding"
                    "set" "get" "implements" "extends")
                  'words)
     . 'font-lock-keyword-face)
   
   ;; Storage class keywords  
   `(,(regexp-opt '("typedef" "register" "auto" "volatile" "inline"
                    "virtual" "abstract" "override" "final" "sealed")
                  'words)
     . 'font-lock-keyword-face)
   
   ;; Built-in scalar types
   `(,(regexp-opt '("void" "bool" "int" "uint" "float" "double" "half"
                    "int8_t" "uint8_t" "int16_t" "uint16_t" 
                    "int32_t" "uint32_t" "int64_t" "uint64_t"
                    "float16_t" "float32_t" "float64_t"
                    "string" "StringLiteral")
                  'words)
     . 'font-lock-type-face)
   
   ;; Vector and matrix types
   '("\\b\\(bool\\|int\\|uint\\|float\\|double\\|half\\)\\([1-4]\\)\\b" . 'font-lock-type-face)
   '("\\b\\(bool\\|int\\|uint\\|float\\|double\\|half\\)\\([1-4]\\)x\\([1-4]\\)\\b" . 'font-lock-type-face)
   
   ;; Texture and buffer types
   `(,(regexp-opt '("Texture1D" "Texture2D" "Texture3D" "TextureCube"
                    "Texture1DArray" "Texture2DArray" "TextureCubeArray"
                    "Texture2DMS" "Texture2DMSArray"
                    "RWTexture1D" "RWTexture2D" "RWTexture3D"
                    "RWTexture1DArray" "RWTexture2DArray"
                    "Buffer" "RWBuffer" "StructuredBuffer" "RWStructuredBuffer"
                    "ByteAddressBuffer" "RWByteAddressBuffer"
                    "ConstantBuffer" "TextureBuffer" "RWTextureBuffer"
                    "AppendStructuredBuffer" "ConsumeStructuredBuffer"
                    "SamplerState" "SamplerComparisonState"
                    "RasterizerOrderedBuffer" "RasterizerOrderedStructuredBuffer"
                    "RasterizerOrderedTexture1D" "RasterizerOrderedTexture2D"
                    "RasterizerOrderedTexture3D")
                  'words)
     . 'font-lock-type-face)
   
   ;; Built-in interfaces
   `(,(regexp-opt '("IArithmetic" "ILogical" "IComparable" "IFloat"
                    "IInteger" "ISigned" "IUnsigned" "INumeric"
                    "IDifferentiable" "ITexture" "IResource")
                  'words)
     . 'font-lock-type-face)
   
   ;; HLSL semantics and system values
   `(,(regexp-opt '("SV_Position" "SV_Target" "SV_Depth" "SV_Coverage"
                    "SV_VertexID" "SV_InstanceID" "SV_PrimitiveID"
                    "SV_DispatchThreadID" "SV_GroupID" "SV_GroupThreadID"
                    "SV_GroupIndex" "SV_DomainLocation" "SV_InsideTessFactor"
                    "SV_TessFactor" "SV_OutputControlPointID" "SV_GSInstanceID"
                    "POSITION" "NORMAL" "TANGENT" "BINORMAL" "COLOR"
                    "TEXCOORD0" "TEXCOORD1" "TEXCOORD2" "TEXCOORD3"
                    "TEXCOORD4" "TEXCOORD5" "TEXCOORD6" "TEXCOORD7"
                    "BLENDWEIGHT" "BLENDINDICES" "PSIZE" "FOG")
                  'words)
     . 'font-lock-constant-face)
   
   ;; Boolean constants
   `(,(regexp-opt '("true" "false") 'words) . 'font-lock-constant-face)
   
   ;; Built-in mathematical functions
   `(,(regexp-opt '("abs" "acos" "all" "any" "asin" "atan" "atan2"
                    "ceil" "clamp" "cos" "cosh" "cross" "degrees"
                    "determinant" "distance" "dot" "exp" "exp2"
                    "faceforward" "floor" "fmod" "frac" "frexp"
                    "fwidth" "ldexp" "length" "lerp" "log" "log2"
                    "log10" "max" "min" "modf" "mul" "normalize"
                    "pow" "radians" "reflect" "refract" "round"
                    "rsqrt" "saturate" "sign" "sin" "sincos" "sinh"
                    "smoothstep" "sqrt" "step" "tan" "tanh" "transpose"
                    "trunc" "ddx" "ddy" "ddx_coarse" "ddy_coarse"
                    "ddx_fine" "ddy_fine" "tex1D" "tex2D" "tex3D"
                    "texCUBE" "noise" "clip" "discard" "lit")
                  'words)
     . 'font-lock-builtin-face)
   
   ;; Shader function intrinsics
   `(,(regexp-opt '("Sample" "SampleLevel" "SampleBias" "SampleCmp"
                    "SampleCmpLevelZero" "SampleGrad" "Load" "Store"
                    "GetDimensions" "CalculateLevelOfDetail"
                    "CalculateLevelOfDetailUnclamped"
                    "Gather" "GatherRed" "GatherGreen" "GatherBlue"
                    "GatherAlpha" "GatherCmp" "GatherCmpRed"
                    "GatherCmpGreen" "GatherCmpBlue" "GatherCmpAlpha"
                    "GroupMemoryBarrier" "GroupMemoryBarrierWithGroupSync"
                    "DeviceMemoryBarrier" "DeviceMemoryBarrierWithGroupSync"
                    "AllMemoryBarrier" "AllMemoryBarrierWithGroupSync"
                    "InterlockedAdd" "InterlockedAnd" "InterlockedCompareExchange"
                    "InterlockedCompareStore" "InterlockedExchange"
                    "InterlockedMax" "InterlockedMin" "InterlockedOr"
                    "InterlockedXor" "WaveActiveAllEqual" "WaveActiveBallot"
                    "WaveActiveCountBits" "WaveGetLaneCount" "WaveGetLaneIndex"
                    "WaveIsFirstLane" "WaveActiveAnyTrue" "WaveActiveAllTrue"
                    "WaveActiveSum" "WaveActiveProduct" "WaveActiveMin"
                    "WaveActiveMax" "WaveActiveBitAnd" "WaveActiveBitOr"
                    "WaveActiveBitXor" "WavePrefixCountBits" "WavePrefixSum"
                    "WavePrefixProduct" "WaveQuadReadAcrossX" "WaveQuadReadAcrossY"
                    "WaveQuadReadAcrossDiagonal" "WaveQuadSwapX" "WaveQuadSwapY"
                    "WaveReadLaneAt" "WaveReadLaneFirst")
                  'words)
     . 'font-lock-builtin-face)
   
   ;; Number literals
   '("\\b[0-9]+\\(\\.[0-9]+\\)?\\([eE][-+]?[0-9]+\\)?[fFhHlLuU]*\\b" . 'font-lock-constant-face)
   '("\\b0[xX][0-9a-fA-F]+[uUlL]*\\b" . 'font-lock-constant-face)
   
   ;; String literals
   '("\"\\([^\"\\\\]\\|\\\\.\\)*\"" . 'font-lock-string-face)
   '("'\\([^'\\\\]\\|\\\\.\\)*'" . 'font-lock-string-face)
   
   ;; Function definitions
   '("\\b\\([a-zA-Z_][a-zA-Z0-9_]*\\)\\s-*(" (1 'font-lock-function-name-face))
   
   ;; Type names (capitalized identifiers)
   '("\\b[A-Z][a-zA-Z0-9_]*\\b" . 'font-lock-type-face)
   )
  "Font lock keywords for Slang mode.")

;; Imenu support
(defvar slang-imenu-generic-expression
  '(("Functions" "^\\s-*\\([a-zA-Z_][a-zA-Z0-9_<>]*\\)\\s-+\\([a-zA-Z_][a-zA-Z0-9_]*\\)\\s-*(" 2)
    ("Structs" "^\\s-*struct\\s-+\\([a-zA-Z_][a-zA-Z0-9_]*\\)" 1)
    ("Interfaces" "^\\s-*interface\\s-+\\([a-zA-Z_][a-zA-Z0-9_]*\\)" 1)
    ("Enums" "^\\s-*enum\\s-+\\([a-zA-Z_][a-zA-Z0-9_]*\\)" 1)
    ("Classes" "^\\s-*class\\s-+\\([a-zA-Z_][a-zA-Z0-9_]*\\)" 1))
  "Imenu generic expression for Slang mode.")

;; Indentation function
(defun slang-indent-line ()
  "Indent current line as Slang code."
  (interactive)
  (c-indent-line))

;; Electric brace function
(defun slang-electric-brace (arg)
  "Insert a brace and indent properly."
  (interactive "P")
  (self-insert-command (prefix-numeric-value arg))
  (when (and (not arg)
             (eolp)
             (save-excursion
               (skip-chars-backward " \t")
               (bolp)))
    (c-indent-line)))

;; Keymap
(defvar slang-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "{" 'slang-electric-brace)
    (define-key map "}" 'slang-electric-brace)
    (define-key map (kbd "C-c C-c") 'comment-region)
    (define-key map (kbd "C-c C-u") 'uncomment-region)
    map)
  "Keymap for Slang mode.")

;; Mode menu
(easy-menu-define slang-mode-menu slang-mode-map
  "Menu for Slang mode."
  '("Slang"
    ["Comment Region" comment-region (mark)]
    ["Uncomment Region" uncomment-region (mark)]
    "---"
    ["Indent Line" slang-indent-line t]
    ["Indent Region" indent-region (mark)]
    "---"
    ["Customize Slang" (customize-group 'slang) t]))

;;;###autoload
(define-derived-mode slang-mode c-mode "Slang"
  "Major mode for editing Slang shader files."
  :syntax-table slang-mode-syntax-table
  :group 'slang
  
  ;; Font lock
  (setq font-lock-defaults '(slang-font-lock-keywords nil nil nil nil))
  
  ;; Comments
  (setq comment-start "// "
        comment-end ""
        comment-start-skip "\\(//+\\|/\\*+\\)\\s *"
        comment-end-skip "\\s *\\(\\s>\\|\\*+/\\)")
  
  ;; Indentation
  (setq c-basic-offset slang-indent-offset
        tab-width slang-indent-offset
        indent-tabs-mode nil)
  
  ;; Case sensitivity
  (setq case-fold-search nil)
  
  ;; Imenu
  (setq imenu-generic-expression slang-imenu-generic-expression)
  
  ;; Compilation support
  (when (boundp 'compilation-error-regexp-alist)
    (set (make-local-variable 'compilation-error-regexp-alist)
         '(("^\\([^:]+\\):\\([0-9]+\\):" 1 2))))
  
  ;; Run mode hooks
  (run-mode-hooks 'slang-mode-hook))

;; File associations
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.slang\\'" . slang-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.sl\\'" . slang-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.slangh\\'" . slang-mode))

(provide 'slang-mode)

;;; slang-mode.el ends here 