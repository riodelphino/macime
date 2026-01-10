# macime

Alternative to [macism](https://github.com/laishulu/macism) and [im-select](https://github.com/daipeihust/im-select) on macOS.

On older Macs, these tools require `waiting for a moment` each time until switching IME mode.

`macime` is a faster Swift-based IME auto-switching tool, which reduces this latency and also provides additional convenient features.

Thanks for the original swift code:  
[Neovim IMEの状態をカーソルの色に反映させる](https://it.commutty.com/denx/articles/b17c2ef01d10486d90fcf6f26f74fe58) (Japanese)


## Why macime?

1. Written in swift (faster)
2. Reduce time lag 10-60% than similar tools. (It depends the command usages.)
3. Rich features
4. Easy setup to nvim


## Feature

* Show the current IME
* List all available IMEs
* Output results in plain text or JSON
* Switch to a specified IME
* Switch IME while saving the previous one
* Restore the previously used IME


## Requirements

* macOS
* bash or zsh (May work with other shells)


## Install

```bash
brew tap riodelphino/tap
brew install macime
```

## Uninstall

```bash
brew uninstall macime
```

## Setup

`macime set` with `--save` option keeps previous IME as files in temporaly directory.
Default save directory is `/tmp/riodelphino.macime`.

To change it, add this line in `~/.profile`:
```bash
export MACIME_TEMP_DIR="/path/to/your/temp_dir"
```
Make sure you have write/read permissions to the directory.


## Usage

Show `macime` version:
```bash
macime --version
# macime v2.x.x
```

Show `macime` help:
```bash
macime --help
```

Sub commands:
```bash
macime get [options]
macime set <IME_ID> [options]
macime list [options]
macime load [options]
```

`get`
Show the current IME.

`set`
Switch to the specified IME.
Optionally saves the previous IME.

`list`
List available IMEs.

`load`
Restore the previously saved IME.


### Get current IME
```bash
macime get
# com.apple.keylayout.ABC

macime get --detail
# id: com.apple.keylayout.ABC
# localizedName: ABC
# isSelectCapable: true
# isSelected: true
# sourceLanguages: ["en", "af", ... "zu"]

macime get --detail --json
# {"isSelectCapable":true,"isSelected":true,"sourceLanguages":["en","af", ... ,"zu"],"localizedName":"ABC","id":"com.apple.keylayout.ABC"}
```

### Set IME
```bash
# Set IME
macime set com.apple.keylayout.ABC

# Set IME & save previous IME as `DEFAULT`
macime set com.apple.keylayout.ABC --save
# previous IME ID is saved at `/tmp/riodelphino.macime/prev/DEFAULT`

# Set IME & save previous IME as <session_id>
macime set com.apple.keylayout.ABC --save --session-id nvim-1001
# previous IME ID is saved at `/tmp/riodelphino.macime/prev/nvim-1001`
```

### Load IME
```bash
# Load IME from `DEFAULT`
macime load
# Read previous IME ID from `/tmp/riodelphino.macime/prev/DEFAULT`, then set it.

# Load IME from `<session_id>`
macime load --session-id nvim-1001
# Read previous IME ID from `/tmp/riodelphino.macime/prev/nvim-1001`, then set it.
```

### List IME
```bash
macime list # id list
macime list --detail # detailed list
macime list --json # json list
macime list --select-capable # show only selectable IME methods
# --detail, --json and --select-capable can be mixtured
```

## Integration

### Neovim

(Recommended) Install wrapper plugin:
[riodelphino/macime.nvim](https://github.com/riodelphino/macime.nvim)

For more details, see [doc/integration.md](doc/integration.md).


## Stored in Temporary dir

The previous IME ID is stored in `/tmp/riodelphino.macime/<session_id>`.  
These files are deleted when you shutdown macOS.


## Tips

For faster switching with low latency, set this config in `init.lua`:
```lua
vim.o.timeoutlen = 0 -- 0 ~ 50
```

> [!Warning]
> This config affects other keybinds in `nvim`.


## Known Issues

- Occasionally it becomes impossible to set the IME mode `ON` by `right cmd` key with `karabiner`.
   - `left cmd` = IME OFF (EISU) / `right cmd` = IME ON (KANA), in my karabiner config.
   - Which is this issue releated to `macime` or `Karabiner`?
   - Solutions: To solve it temporaly, set the IME `OFF` by `left cmd` key

- `azookey` | [azookey-Desktop](https://github.com/azooKey/azooKey-Desktop) avoid `macime set` command to work.
   - I guess it's because they are still alpha version.
   - Solutions: Uninstalling them solves it.


## Contribute

Contributions are welcome:
```bash
# Clone
git clone https://github.com/riodelphino/macime
cd macime

# Build
swift build
```


## Changelog

See [CHANGELOG](CHANGELOG.md)


## License

MIT License. See [LICENSE](LICENSE)


## Refers

- [Neovim IMEの状態をカーソルの色に反映させる](https://it.commutty.com/denx/articles/b17c2ef01d10486d90fcf6f26f74fe58) (Japanese)


## Related

- [im-select](https://github.com/daipeihust/im-select)
- [macism](https://github.com/laishulu/macism)
- [macime.nvim](https://github.com/riodelphino/macime.nvim)

