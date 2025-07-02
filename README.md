# ime-select.swift

An alternative for [im-select](https://github.com/daipeihust/im-select) in MacOS.

In nvim there was a slight time lag after executing the `im-select` command, so I had to wait a little.
This code is written in swift, so faster than `im-select`. (Though time lag still remains.)

The original code is here. Thank you for sharing!
[https://it.commutty.com/denx/articles/b17c2ef01d10486d90fcf6f26f74fe58](https://it.commutty.com/denx/articles/b17c2ef01d10486d90fcf6f26f74fe58)


## Compile
```bash
swiftc src/ime-select.swift -o src/ime-select
```

## Usage

### List up current & all input methods
```bash
src/ime-select
# `isSelected:[true]`     : Current selected input method.
# `isSelectCapable:[true]`: Available to be selected.
```

### Select methods
```bash
# Select English input method
src/ime-select com.apple.keylayout.ABC

# Select Japanese(MacOS) input method
src/ime-select com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese

# Select Google Japanese input method
src/ime-select com.google.inputmethod.Japanese.base
```


## Reffer

- [https://it.commutty.com/denx/articles/b17c2ef01d10486d90fcf6f26f74fe58](https://it.commutty.com/denx/articles/b17c2ef01d10486d90fcf6f26f74fe58)
