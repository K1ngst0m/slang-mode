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

## Installation

### Vanilla Emacs

1. Download or clone the `slang-mode.el` file
2. Place it in a directory in Emacs load path
3. Add to your `.emacs` or `init.el`:

```elisp
(require 'slang-mode)
```

### Straight.el

```elisp
(use-package slang-mode
  :straight (:host github :repo "k1ngst0m/slang-mode")
  :mode (("\\.slang\\'" . slang-mode)
         ("\\.sl\\'" . slang-mode)
         ("\\.slangh\\'" . slang-mode)))
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
         ("\\.slangh\\'" . slang-mode)))
```

Then run `doom sync`

### Spacemacs

Add to your `dotspacemacs-additional-packages`:

```elisp
(setq-default dotspacemacs-additional-packages
              '((slang-mode :location (recipe :fetcher github
                                              :repo "k1ngst0m/slang-mode"))))
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

## Requirements

- Emacs 24.3 or later

## License

MIT License 
