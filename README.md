# macime

A noticiably faster IME switching tool for macOS. (written in Swift)


## Story

I've used [macism](https://github.com/laishulu/macism) and [im-select](https://github.com/daipeihust/im-select) before.  
But on my older Macs, these tools always required `a short wait` to switch IME modes.

`macime` noticiably reduces this latency.

Though it still has a slight delay, but I’m very satisfied with the switching speed since v3.0.1.

If you’re a Mac user frustrated by slow IME switching, give it a try. 


## Why it’s fast

1. Sets and gets the IME in a single operation
2. Uses a launchd daemon service
3. Written in native Swift


## Feature

* Get current IME
* Set a specified IME
* Save current IME
* Load(Restore) the previous IME
* Switch IME while saving the previous one (in single step)
* List all IMEs
* Output results in plain text or JSON


## Requirements

* macOS


## Install

```bash
brew tap riodelphino/tap
brew install macime
```

## Uninstall

```bash
brew uninstall macime
```

## Start/Stop Service

Optional. Maybe slightly faster.

```bash
# Start macimed service
brew services start macime

# Stop macimed service
brew services stop macime

# Manually start (for test, to see the log)
macimed
```

## Usage

### macime

Show `macime` version:
```bash
macime --version
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
macime save [options]
macime load [options]
```

`get`
Show the current IME.

`set`
Switch to the specified IME.
Optionally saves the previous IME.

`list`
List available IMEs.

`save`
Save current IME.

`load`
Restore the previous IME.


#### Get current IME
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

#### Set IME
```bash
# Set IME
macime set com.apple.keylayout.ABC

# Set IME while saving current IME as `DEFAULT`
macime set com.apple.keylayout.ABC --save
# The IME ID is saved at `/tmp/riodelphino.macime/prev/DEFAULT`

# Set IME while saving current IME as <session_id>
macime set com.apple.keylayout.ABC --save --session-id nvim-1001
# The IME ID is saved at `/tmp/riodelphino.macime/prev/nvim-1001`
```
#### Save IME
```bash
# Save current IME to `DEFAULT`
macime save
# Current IME ID is set to `/tmp/riodelphino.macime/prev/DEFAULT`

# Save current IME to `<session_id>`
macime save --session-id nvim-1001
# Current IME ID is set to `/tmp/riodelphino.macime/prev/nvim-1001`
```

#### Load IME
```bash
# Load IME from `DEFAULT`
macime load
# Reads previous IME ID from `/tmp/riodelphino.macime/prev/DEFAULT`, then set it.

# Load IME from `<session_id>`
macime load --session-id nvim-1001
# Reads previous IME ID from `/tmp/riodelphino.macime/prev/nvim-1001`, then set it.
```

#### List IME
```bash
macime list # id list
macime list --detail # detailed list
macime list --json # json list
macime list --select-capable # show only selectable IME methods
# --detail, --json and --select-capable can be mixtured
```

### macimed

`macimed` command is bundled with `macime`.  
This command is used by `launchd` if you enabled it by `brew services start macime`.

You can manually start it by `macimed` to monitor log.

#### macimed Log

`macimed` leaves log and err in:

Log:
* /usr/local/var/log/macimed.log
* /opt/homebrew/var/log/macimed.log (Apple Silicon)

Error:
* /usr/local/var/log/macimed.err
* /opt/homebrew/var/log//macimed.err (Apple Silicon)


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


## Issues

### azookey prevents macime to change IME

`azookey` | [azookey-Desktop](https://github.com/azooKey/azooKey-Desktop) prevents `macime set` command to work.
I guess it's because they are still alpha version.

Solutions for now:
   - Uninstal `azookey`


## Contribution

Contributions are welcome:
```bash
# Clone
git clone https://github.com/riodelphino/macime
cd macime

# Build for debug
swift build
# Build for release
swift build -c release
```

## Others

**Deprecated**: `$MACIME_TEMP_DIR` environmental value


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

