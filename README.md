# ime-select.swift

> [!Warning]
> Still a prototype. Use with caution. Feedback and issues are welcome!

An alternative for [im-select](https://github.com/daipeihust/im-select) in MacOS.

In nvim, there was a slight time lag after executing the `im-select` command.

This code is written in swift, so 10-60% faster than `im-select`. (It depends the commands.)

The original swift code is here. Thank you for sharing!
[https://it.commutty.com/denx/articles/b17c2ef01d10486d90fcf6f26f74fe58](https://it.commutty.com/denx/articles/b17c2ef01d10486d90fcf6f26f74fe58)


## Feature

* Show current IME method
* Show IME List
* Select IME method
* Toggle several IME methods in sequence
* Save current IME method, and Load it later
* Save and select at once (less time lag)
* Choose output format from plain-text(default) or json-text


## Install
```bash
cd src
# swiftc ime-select.swift -o ime-select # If you modified source code
sudo ln -s "$(pwd)/ime-select" /usr/local/bin/ime-select
```

## Uninstall
```bash
sudo rm /usr/local/bin/ime-select
```

## Usage

### Show current IME method
```bash
./ime-select
# com.apple.keylayout.ABC

./ime-select --detail
# id: com.apple.keylayout.ABC
# localizedName: ABC
# isSelectCapable: true
# isSelected: true
# sourceLanguages: ["en", "af", ... ]
# --------------------

./ime-select --detail --json
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
ime-select --list # id list (e.g. com.apple.keylayout.ABC)
ime-select --list --name # name list (e.g. ABC)
ime-select --list --detail # detailed list
ime-select --list --json # json list
ime-select --list --available # filter only available to be selected
```

### Select IME methods
```bash
# Select English input method
ime-select com.apple.keylayout.ABC

# Select Japanese(MacOS) input method
ime-select com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese

# Select Google Japanese input method
ime-select com.google.inputmethod.Japanese.base
```

### Toggle IME methods
```bash
# Toggle 1 -> 2 -> 3 -> 1 ...
ime-select --toggle com.apple.keylayout.ABC,com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese,com.google.inputmethod.Japanese.base
```
IME methods are separated by ','.

### Save and Load IME methods
```bash
ime-select --save # Save only
ime-select --save com.apple.keylayout.ABC # Save and Select at once
ime-select --load # Load saved IME
```

#### Sample use cases

Use `--save` When you exit insert-mode in nvim, Use `--load` when you return to insert-mode to restore.


#### Comparison

`im-select`:
Need calling twice. Check IME method by `im-select` -> Select IME method `im-select com.apple.keylayout.ABC`)

`ime-select`:
Save and select at once! Less time lag!


## Reffer

- [https://it.commutty.com/denx/articles/b17c2ef01d10486d90fcf6f26f74fe58](https://it.commutty.com/denx/articles/b17c2ef01d10486d90fcf6f26f74fe58)

