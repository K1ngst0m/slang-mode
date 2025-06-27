# Slang (Shader) Mode for Emacs

This is a major mode for Emacs for the Slang Shading Language

## Features

- **Syntax Highlighting**:
  - Core language keywords (`interface`, `struct`, `enum`, `module`, `import`, etc.)
  - Built-in types (scalar, vector, matrix types like `float3`, `int4x4`)
  - Texture and buffer types (`Texture2D`, `RWBuffer`, `StructuredBuffer`, etc.)
  - HLSL semantics (`SV_Position`, `SV_Target`, `TEXCOORD0`, etc.)
  - Built-in functions and intrinsics (`sin`, `cos`, `Sample`, `WaveActiveSum`, etc.)
  - Preprocessor directives and attributes
- **C-style Indentation**: Proper indentation based on C-mode
- **Comment Support**: Both single-line (`//`) and multi-line (`/* */`) comments
- **Electric Braces**: Automatic indentation when inserting `{` and `}`
- **Imenu Support**: Navigation of functions, structs, interfaces, enums, and classes

## LSP Support

Optional Language Server Protocol integration via `slang-lsp.el`:

- **Real-time Diagnostics**: Error checking as you type
- **Code Completion**: Context-aware autocompletion 
- **Go to Definition**: Jump to symbol definitions (`C-c l d`)
- **Hover Documentation**: View documentation on hover (`C-c l h`)
- **Code Formatting**: Format code with slangd (`C-c l f`)
- **Symbol Renaming**: Rename across project (`C-c l n`)
- **Signature Help**: Function parameter hints

**Requirements**: 
- `slangd` language server from [Slang releases](https://github.com/shader-slang/slang/releases) or Vulkan SDK
- `eglot` (built into Emacs 29+)

**Note**: Current slangd version doesn't support find references, implementation, or type definition.

## Installation

### Vanilla Emacs

1. Download or clone the `slang-mode.el` file
2. Place it in a directory in Emacs load path
3. Add to your `.emacs` or `init.el`:

```elisp
(require 'slang-mode)
;; Optional: Enable LSP support
(require 'slang-lsp)
(slang-lsp-initialize)
```

### Straight.el

```elisp
(use-package slang-mode
  :straight (:host github :repo "k1ngst0m/slang-mode")
  :mode (("\\.slang\\'" . slang-mode)
         ("\\.sl\\'" . slang-mode)
         ("\\.slangh\\'" . slang-mode))
  :config
  ;; Optional: Enable LSP support
  (require 'slang-lsp)
  (slang-lsp-initialize))
```

### Doom Emacs

Add to your `packages.el`:
```elisp
(package! slang-mode
  :recipe (:host github :repo "k1ngst0m/slang-mode"))
```

Add to your `config.el`:
```elisp
(use-package! slang-mode
  :mode (("\\.slang\\'" . slang-mode)
         ("\\.sl\\'" . slang-mode)
         ("\\.slangh\\'" . slang-mode))
  :config
  ;; Optional: Enable LSP support
  (require 'slang-lsp)
  (slang-lsp-initialize))
```

Then run `doom sync`

### Spacemacs

Add to your `dotspacemacs-additional-packages`:

```elisp
(setq-default dotspacemacs-additional-packages
              '((slang-mode :location (recipe :fetcher github
                                              :repo "k1ngst0m/slang-mode"))))

;; In dotspacemacs/user-config, optionally enable LSP:
(with-eval-after-load 'slang-mode
  (require 'slang-lsp)
  (slang-lsp-initialize))
```

## Usage

### File Association

The mode automatically activates for files with these extensions:
- `.slang` - Slang source files
- `.sl` - Slang source files  
- `.slangh` - Slang header files

### Customization

The mode provides a customization group accessible via:
```elisp
M-x customize-group RET slang RET
```

Available customizations:
- `slang-indent-offset`: Indentation offset for Slang code (default: 4)

### Programming Features

- **Syntax Highlighting**: Comprehensive highlighting of all Slang language constructs
- **Indentation**: C-style indentation that properly handles Slang syntax
- **Comments**: Proper handling of both `//` single-line and `/* */` multi-line comments

### LSP Features (when enabled)

- **Auto-completion**: Press `Tab` or `C-i` for context-aware suggestions
- **Go to Definition**: `C-c l d` to jump to symbol definitions
- **Hover Documentation**: `C-c l h` to view symbol documentation
- **Code Formatting**: `C-c l f` to format current buffer
- **Symbol Renaming**: `C-c l n` to rename symbols across project
- **Menu Access**: Use `Slang > LSP` menu for all LSP commands

## Requirements

- `slang-mode` requires **Emacs 24.3 or later**
- `slang-lsp` (LSP integration) requires **Emacs 26.1 or later** and `eglot` (version 1.4+ or Emacs 29+)

## License

MIT License 
