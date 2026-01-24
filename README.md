# macime

A **blazing faster** IME switching tool for macOS. (Swift / launchd service)


## Story

I've used [macism](https://github.com/laishulu/macism) and [im-select](https://github.com/daipeihust/im-select) before.  
But on my older Macs, these tools always required `a short wait` to switch IME modes. It was an unacceptable delay for daily use.

`macime` significantly reduces this delay by **30% to 70%**. (Depends on usage.)

Though it still has a slight delay, but I’m very satisfied with the switching speed since v3.x.

If you’re a Mac user frustrated by slow IME switching, give it a try. 


## Why it’s fast

1. Sets and gets the IME in a single operation
2. Uses a launchd service
3. Written in native Swift
4. Optimized code


## Feature

* Get current IME
* Set a specified IME
* Save current IME
* Load(Restore) the previous IME
* Switch IME while saving the previous one (in single step)
* List all IMEs
* Output results in plain text or JSON string
* Faster switching by `macimed` launchd service


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

## Upgrade

```bash
brew update
brew upgrade macime
```
If launchd service is enabled, ensure to restart it:
```bash
brew services restart macime
```

## Register as a launchd Service

Optional, but **STRONGLY RECOMMENDED !!**.  
**30% faster** than running `macimed` directly. (e.g. 128ms -> 89ms)

```bash
# Start macimed service
brew services start macime

# Stop macimed service
brew services stop macime

# Manually start (for test, can see the log)
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

> [!Note]
> Using `set` and `--save` together reduces elapsed time **50%**.
> While other tools need two excution like `<command_name>` -> `<command_name> set com.apple.keylayout.ABC`


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

`macimed` is bundled with `macime`.

#### Start macimed

**Recommended (Faster)**
`macimed` can be managed by `launchd` via Homebrew:
```bash
brew services start macime
# Although the service name is `macime`, it runs `macimed` internally.
```
When launched this way, execution is typically about **30%** faster than running it manually.

**For Debugging (Slower)**
You can also start `macimed` manually to monitor logs and observe its behavior:
```bash
macimed
```
Useful for debuging, but performance will be slower.

#### sock path

`macimed` listens to:
* /tmp/riodelphino.macime.sock

#### macimed Log

`macimed` leaves log and err.  

Directly running `macimed`:
* /tmp/riodelphino.macimed.log
* /tmp/riodelphino.macimed.err

Via `brew services` (Apple Intel):
* /usr/local/var/log/riodelphino.macimed.log
* /usr/local/var/log/riodelphino.macimed.err

Via `brew services` (Apple Silicon):
* /opt/homebrew/var/log/riodelphino.macimed.log
* /opt/homebrew/var/log/riodelphino.macimed.err


## Integration

### Neovim

(Recommended) Install wrapper plugin:
[riodelphino/macime.nvim](https://github.com/riodelphino/macime.nvim)

For more details, see [doc/integration.md](doc/integration.md).


## Stored in Temporary dir

The previous IME ID is stored in:

When directly executing `macimed`:
* `/tmp/riodelphino.macime/<session_id>`

With `brew services start`:
* `/private/tmp/riodelphino.macime/<session_id>`

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

