# macime

Alternative to [macism](https://github.com/laishulu/macism) and [im-select](https://github.com/daipeihust/im-select) on macOS.

On older Macs, these tools require `waiting for a moment` each time until switching IME mode.

`macime` is a faster Swift-based IME auto-switching tool, which reduces this latency and also provides additional convenient features.

Thanks for the original swift code:  
[https://it.commutty.com/denx/articles/b17c2ef01d10486d90fcf6f26f74fe58](https://it.commutty.com/denx/articles/b17c2ef01d10486d90fcf6f26f74fe58)


## Why macime?

1. Written in swift (faster)
2. Reduce time lag 10-60% than similar tools. (It depends the command usages.)
3. Rich features
4. Easier setup to nvim


## Feature

* Show current IME method
* Show IME methods list
* Select an IME method
* Toggle several IME methods in sequence
* Save current IME method, and Load it later
* Save and select at once (less time lag)
* Choose output format from plain-text(default) or json-text


## Requirements

* macOS


## Install
```bash
git clone https://github.com/riodelphino/macime
cd macime

# Create link
sudo ln -s "$(pwd)/macime" /usr/local/bin/macime
# Or just add to PATH
export PATH=$PATH:$(pwd)
```

## Uninstall
```bash
sudo rm /usr/local/bin/macime
```

## Compile

Only when you modified the source code, compile it (basically not necessary):
```bash
swiftc src/macime.swift -o macime
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
IME methods should be separated by `,`

### Save and Load IME methods
```bash
macime --save # Save only
macime --save com.apple.keylayout.ABC # Save and Select at once
macime --load # Load saved IME
```

## Setup for nvim

* Use `--save` when you exit insert-mode, to save current IME method.
* Use `--load` when you return to insert-mode, to restore it.

init.lua:
```lua
vim.api.nvim_create_autocmd('InsertLeave', {
   callback = function() vim.fn.jobstart({ 'macime', '--save', 'com.apple.keylayout.ABC' }) end,
})

vim.api.nvim_create_autocmd('InsertEnter', {
   callback = function() vim.fn.jobstart({ 'macime', '--load' }) end,
})
```
It works with such a tiny code, and faster!

To exclude specific filetypes:
```lua
vim.api.nvim_create_autocmd('InsertLeave', {
   callback = function() vim.fn.jobstart({ 'macime', '--save', 'com.apple.keylayout.ABC' }) end,
})

vim.api.nvim_create_autocmd('InsertEnter', {
   callback = function()
      local exclude_list = { 'TelescopePrompt', 'snacks_picker_input' }
      local filetype = vim.bo.filetype
      local is_allowed_filetype = not vim.tbl_contains(exclude_list, filetype)
      if is_allowed_filetype then vim.fn.jobstart({ 'macime', '--load' }) end
   end,
})

```
## Show and Delete the defaults key

```bash
defaults read macime # to read the key
defaults delete macime # to delete the key
```

## Known Issues

- Occasionally it becomes impossible to set the IME mode `ON` by `right cmd` key with `karabiner`.
   - `left cmd` = IME OFF (EISU) / `right cmd` = IME ON (KANA), in my karabiner config.
   - To solve it temporaly, set the IME `OFF` by `left cmd` key
   - I'm not sure which cause this issue, `karabiner` or `macime`.


## Refers

- [https://it.commutty.com/denx/articles/b17c2ef01d10486d90fcf6f26f74fe58](https://it.commutty.com/denx/articles/b17c2ef01d10486d90fcf6f26f74fe58)


## Related

- [im-select](https://github.com/daipeihust/im-select)
- [macism](https://github.com/laishulu/macism)

