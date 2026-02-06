# macime

[![License: MIT](https://img.shields.io/badge/License-MIT-%232196F3.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Swift](https://img.shields.io/badge/Swift-5.x-orange.svg?style=for-the-badge&logo=swift&logoColor=white)](https://www.swift.org/)
[![Easy Install](https://img.shields.io/badge/Easy%20Install-Homebrew-%23FBB040?style=for-the-badge)](#installation)
[![Platform](https://img.shields.io/badge/Platform-macOS%2010.13%2B-blue?style=for-the-badge)](#)

A **blazing faster** IME switching tool for macOS. (Swift via launchd service)


## Breaking Changes

* [v3.6.0](https://github.com/riodelphino/macime/releases/tag/v3.6.0):
    * Deprecate `--status` `--sock-path` `--macime-path` options from `macimed` (They don't reflect environmental variable)
    * Deprecate `--launchd` option from `macime` (Doesn't work in some cases)
    * Allow `macimed` socket command to handle both `ime` and `daemon` methods (e.g. `ime set com.apple...`, `daemon sockpath`)
    * Upgrade macOS version (10.13 -> 10.15)
* [v3.5.0](https://github.com/riodelphino/macime/releases/tag/v3.5.0): Add CJK refreshing (Experimental and untested)
* [v3.4.0](https://github.com/riodelphino/macime/releases/tag/v3.4.0): Revive `$MACIME_TEMP_DIR` env and Add `$MACIME_SOCK_PATH`
* [v3.3.3](https://github.com/riodelphino/macime/releases/tag/v3.3.3): Deprecate `--json` option (Use `--detail` option instead)
* [v3.0.0](https://github.com/riodelphino/macime/releases/tag/v3.0.0): Deprecate `$MACIME_TEMP_DIR` environmental value


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
* List all IMEs
* Switch IME while saving the previous one (in single step)
* Output detailed get|list results as JSON
* Faster switching by `macimed` launchd service
* Fallback to `im-select` style command usage
* Refresh IME for CJK input methods (Experimental and untested)


## Requirements

* macOS (>=10.15)


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

## Run as a launchd Service

`macimed` can be managed by `launchd` via Homebrew.

It's optional, but STRONGLY RECOMMENDED!!  
**30% faster** than running `macimed` manually. (e.g. 128ms -> 89ms)
```bash
# Start `macimed` service
brew services start macime

# Stop `macimed` service
brew services stop macime
```
> [!Note]
> Although the service name is `macime`, it runs `macimed` internally.


Or, you can also start `macimed` manually to monitor logs and observe its behavior:
```bash
macimed
```
Useful for debuging, but performance will be slower.


## Usage

### macime

Show `macime` version:
```bash
macime --version
macime -v
```

Show `macime` help:
```bash
macime --help
macime -h
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


#### Fallback behavior (im-select compatible)

`macime` supports im-select–style shortcuts.

```bash
# Falls back to `macime get`
macime

# Falls back to `macime set`
macime com.apple.keylayout.ABC
```

#### Get current IME
```bash
# Get current IME ID
macime get
# com.apple.keylayout.ABC

# Get current IME detailed info as JSON
macime get --detail
# {
#   "isSelectCapable" : true,
#   "isSelected" : true,
#   "localizedName" : "ABC",
#   "id" : "com.apple.keylayout.ABC",
#   "sourceLanguages" : [
#     "en",
#     ...
#     "zu"
#   ]
# }


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
# Show IME ID list
macime list

# Show IME detailed list as JSON
macime list --detail

# Show only selectable IME
macime list --select-capable
```
> [!Note]
> `--detail` and `--select-capable` can be mixtured

### Options

| Option                    | Available for | Description                                                         |
| ------------------------- | ------------- | ------------------------------------------------------------------- |
| --detail                  | get, list     | Show detailed IME info as JSON                                      |
| --select-capable          | get, list     | Show only selectable IME                                            |
| --save                    | set           | Save current IME (with `macime set` only)                           |
| --session-id <session_id> | save, load    | Specify the save / load session id (= filename in temp dir)         |
| --cjk-refresh             | set, load     | Refresh IME for CJK input methods (Experimental and untested)       |

### CJK refreshing

> [!Warning]
> Experimental and untested. Please test in your environment, then report any issues or submit a PR.

`macime` can refresh IME for CJK input methods (e.g. `百度拼音`, `搜狗拼音`).

via `--cjk-refresh` option:
```bash
# Set
macime set com.baidu.inputmethod.BaiduPinyin --cjk-refresh
macime set com.sogou.inputmethod.sogou --cjk-refresh

# load
macime load --cjk-refresh
```

### macimed

`macimed` is a daemon bundled with `macime`. It enables blazing faster IME switching.  
It runs in the background and controls `macime` by receiving commands over a Unix domain socket.

Run `macimed` manually (for debugging):
```bash
macimed
# It shows useful err/log
```

Show the `macimed` version:
```bash
macimed --version
macimed -v
```

Show the `macimed` help:
```bash
macimed --help
macimed -h
```

#### Default Socket Path

`macimed` listens to:
* /tmp/riodelphino.macime.sock

#### Send Commands

`macimed` recieves commands via socket as plain text.

Commands compliant to `macime`:
```bash
ime set com.apple.keylayout.ABC
ime set com.apple.keylayout.ABC --save
ime set com.apple.keylayout.ABC --save --session-id <session-id>
ime load
ime load --session-id <session-id>
```

When the socket recieves a command like above, `macimed` executes `macime` command with these args immediately.

Commands for `macimed`:
```bash
# Get all informations of `macimed`
daemon info

# Get
daemon sockpath # Get sock path
daemon macimepath # Get macime path

# Set
daemon sockpath /tmp/riodelphino.macime.sock # Set sock path
daemon macimepath /Users/yourname/project/macime/.build/release/macime # Set macime path
```

To test these commands via `macime.nvim` (Ensure `macimed` is running):
(e.g.)
```lua
require("macime").send("ime set com.apple.keylayout.ABC")
require("macime").send("ime get", function(ok, data) if ok then print(data) end end)
require("macime").send("daemon sockPath /tmp/path/to/another.sock")
require("macime").send("daemon info", function(ok, data) if ok then print(data) end end)
require("macime").send("daemon sockPath", function(ok, data) if ok then print(data) end end)
```


#### Temporary directory used by macimed to stores IME IDs

Previous IME IDs are stored in the following paths.

When running `macimed` manually (socket):
* /tmp/riodelphino.macime/DEFAULT
* /tmp/riodelphino.macime/<session_id>

When running via `Homebrew service`:
* /private/tmp/riodelphino.macime/DEFAULT
* /private/tmp/riodelphino.macime/<session_id>

These files are deleted when you shutdown macOS.


## Technical Information

### Logs

`macimed` leaves `stdout` and `stderr` logs when it is running via `Homebrew service`.

With `Apple Intel`:
* /usr/local/var/log/riodelphino/macimed.out.log
* /usr/local/var/log/riodelphino/macimed.err.log

With `Apple Silicon`:
* /opt/homebrew/var/log/riodelphino/macimed.out.log
* /opt/homebrew/var/log/riodelphino.macimed.err.log

### plist path via Homebrew

plist path:
* ~/Library/LaunchAgents/homebrew.mxcl.macime.plist

### macime Executable Path

`macimed` requires the full-path of `macime`, and it is automatically determined from one of the following paths:
- `MACIME_PATH` (Environment variable)
- /usr/local/bin/macime (Homebrew on Intel Mac)
- /opt/homebrew/bin/macime (Homebrew on Apple Silicon)

### MACIME_PATH Enviroment Variable

The `MACIME_PATH` is set at `brew install` time via `riodelphino/homebrew-tap/Fomula/macime.rb`:
```ruby
service do
  ...
  environment_variables(
    MACIME_PATH: opt_bin/"macime"
  )
  ...
end
```

### Sock path

`macimed` determine the sock path from one of the following paths:
- `MACIME_SOCK_PATH` (Environment variable)
- `/tmp/riodelphino.macimed.sock`

### Temp dir

`macimed` determine the temp dir from one of the following paths:
- `MACIME_TEMP_DIR` (Environment variable)
- `/tmp/riodelphino.macime`


## Integration

### Neovim

(Recommended) Install wrapper plugin:
[riodelphino/macime.nvim](https://github.com/riodelphino/macime.nvim)

It enables `macime`, `macimed` and `Homebrew service` without extra codings.


## Issues

### azookey prevents macime to change IME

`azookey` | [azookey-Desktop](https://github.com/azooKey/azooKey-Desktop) prevents `macime set` command to work.
I guess it's because they are still alpha version.

Solutions for now:
   - Uninstal `azookey`

### Fix errors on install or upgrade

> [!Note]
> This error was caused by a merge conflict in the tap repository. Sorry for my git mistake.

If you encounter a syntax error during `install`/`reinstall`/`upgrade` macime:
```txt
Error: riodelphino/tap/macime: /usr/local/Homebrew/Library/Taps/riodelphino/homebrew-tap/Formula/macime.rb:2: syntax errors found
...
<<<<<<< HEAD
...
~~~~~~
...
=======
```
Resolve it with the follwing steps:
```bash
# Remove macime and the tap
brew uninstall macime
brew untap riodelphino/tap
# Reinstall the tap and macime
brew tap riodelphino/tap
brew install macime
```
This cleans up the corrupted tap cache and performs a fresh installation.


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

For debugging, temporary force the built `macimed` use the built `macime`:
```bash
MACIME_PATH=/path/to/macime/.build/release/macime macimed
```

## Thanks To

- The IME switching concept is inspired by [im-select](https://github.com/daipeihust/im-select) and [macism](https://github.com/laishulu/macism)
- The CJK IME workaround is inspired by [ims-mac](https://github.com/LuSrackhall/ims-mac)
- The idea that Swift can manipulate IME states was inspired by
  [Neovim IMEの状態をカーソルの色に反映させる](https://it.commutty.com/denx/articles/b17c2ef01d10486d90fcf6f26f74fe58) (Japanese)


## Changelog

See [CHANGELOG](CHANGELOG.md)


## License

MIT License. See [LICENSE](LICENSE)


## Related

- [im-select](https://github.com/daipeihust/im-select)
- [macism](https://github.com/laishulu/macism)
- [ims-mac](https://github.com/LuSrackhall/ims-mac)
- [macime.nvim](https://github.com/riodelphino/macime.nvim)

