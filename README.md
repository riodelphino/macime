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


## version

`v2.1.0`

Totally modified and refactored from `v1.x`.  
`v2.x` saves the previous IME in `/tmp` dir.


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

1. Clone
```bash
git clone https://github.com/riodelphino/macime
```
2. Install (Choose one)

A. Create symlink (Recommended):
```bash
sudo ln -s /path/to/macime/macime /usr/local/bin/macime
```

B. Add to PATH in `.profile` or `.zprofile`:
```bash
export PATH="$PATH:/path/to/macime"
```

## Uninstall

A. Remove symlink:
```bash
sudo rm /usr/local/bin/macime
```

B. Remove the PATH entry in `.profile` or `.zprofile`:
```bash
export PATH="$PATH:/path/to/macime"
```

## Compile

Only when you modified the source code, compile it (basically not necessary):
```bash
cd /path/to/macime
swiftc src/macime.swift -o macime
```

## Usage

Show `macime` version:
```bash
macime --version
# macime v2.1.0
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

The previous IME ID is stored in `/tmp/riodelphino.macime/prev/<session_id>`.  
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
   - To solve it temporaly, set the IME `OFF` by `left cmd` key
   - Which is this issue releated to `macime` or `Karabiner`?

- `azookey` | [azookey-Desktop](https://github.com/azooKey/azooKey-Desktop) avoid `macime set` command to work.
   - Because they are still alpha version.
   - Uninstalling them solves it.


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

