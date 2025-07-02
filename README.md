# macime

> [!Warning]
> Still a prototype. Use with caution. Feedback and issues are welcome!

An alternative for [macism](https://github.com/laishulu/macism) and [im-select](https://github.com/daipeihust/im-select) in MacOS.

`macism` reduces the slight time lag for executing these command in MacOS's nvim, and provide convenient features.

The original swift code is here. Thank you for sharing!
[https://it.commutty.com/denx/articles/b17c2ef01d10486d90fcf6f26f74fe58](https://it.commutty.com/denx/articles/b17c2ef01d10486d90fcf6f26f74fe58)


## Why macime?

1. Written in swift (faster)
2. Reduce time lag 10-60% than similar tools. (It depends the command usages.)
3. Rich features
4. Easier implementing to nvim

## Feature

* Show current IME method
* Show IME List
* Select IME method
* Toggle several IME methods in sequence
* Save current IME method, and Load it later
* Save and select at once (less time lag)
* Choose output format from plain-text(default) or json-text


## Requirements

* MacOS


## Install
```bash
git clone https://github.com/riodelphino/macime
cd macime/src
# swiftc macime.swift -o macime # If you modified source code
sudo ln -s "$(pwd)/macime" /usr/local/bin/macime
```

## Uninstall
```bash
sudo rm /usr/local/bin/macime
```

## Usage

### Show current IME method
```bash
macime
# com.apple.keylayout.ABC
# (or)
# com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese

macime --name
# ABC
# (or)
# Hiragana

macime --detail
# id: com.apple.keylayout.ABC
# localizedName: ABC
# isSelectCapable: true
# isSelected: true
# sourceLanguages: ["en", "af", ... ]
# --------------------

macime --detail --json
# {
#   "isSelectCapable" : true,
#   "localizedName" : "ABC",
#   "isSelected" : true,
#   "id" : "com.apple.keylayout.ABC",
#   "sourceLanguages" : [
#     "en",
#     "af",
#     ...
#   ]
# }
```

### List up IME methods
```bash
macime --list # id list (e.g. com.apple.keylayout.ABC)
macime --list --name # name list (e.g. ABC)
macime --list --detail # detailed list
macime --list --json # json list
macime --list --available # show only selectable IME methods
```

### Select IME methods
```bash
# Select English input method
macime com.apple.keylayout.ABC

# Select Japanese(MacOS) input method
macime com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese

# Select Google Japanese input method
macime com.google.inputmethod.Japanese.base
```

### Toggle IME methods
```bash
# Toggle 1 -> 2 -> 3 -> 1 ...
macime --toggle com.apple.keylayout.ABC,com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese,com.google.inputmethod.Japanese.base
```
IME methods should be separated by ','.

### Save and Load IME methods
```bash
macime --save # Save only
macime --save com.apple.keylayout.ABC # Save and Select at once
macime --load # Load saved IME
```

## Setup for nvim

for nvim:
* Use `--save` when you exit insert-mode, to save current IME method.
* Use `--load` when you return to insert-mode, to restore it.

init.lua:
```lua
vim.api.nvim_create_autocmd('InsertEnter', {
   callback = function() vim.fn.jobstart({ 'macime', '--load' }) end,
})

vim.api.nvim_create_autocmd('InsertLeave', {
   callback = function() vim.fn.jobstart({ 'macime', '--save', 'com.apple.keylayout.ABC' }) end,
})
```
It works with such a tiny code, and faster!


## Reffer

- [https://it.commutty.com/denx/articles/b17c2ef01d10486d90fcf6f26f74fe58](https://it.commutty.com/denx/articles/b17c2ef01d10486d90fcf6f26f74fe58)


## Related projects

- [im-select](https://github.com/daipeihust/im-select)
- [macism](https://github.com/laishulu/macism)

