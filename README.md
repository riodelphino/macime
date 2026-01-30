# macime

[![License: MIT](https://img.shields.io/badge/License-MIT-%232196F3.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Swift](https://img.shields.io/badge/Swift-5.x-orange.svg?style=for-the-badge&logo=swift&logoColor=white)](https://www.swift.org/)
[![Easy Install](https://img.shields.io/badge/Easy%20Install-Homebrew-%23FBB040?style=for-the-badge)](#installation)
[![Platform](https://img.shields.io/badge/Platform-macOS%2010.13%2B-blue?style=for-the-badge)](#)

A **blazing faster** IME switching tool for macOS. (Swift via launchd service)


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
* Output results in plain text or JSON string
* Faster switching by `macimed` launchd service
* Fallback to `im-select` style command usage


## Requirements

* macOS (>=10.13)


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
# Start `macimed` service (Faster)
brew services start macime

# Stop `macimed` service
brew services stop macime

# Manually start `macimed` for debugging to see the log (Slower)
macimed
```

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

### Options

| Option                    | Available for | Description                                                         |
| ------------------------- | ------------- | ------------------------------------------------------------------- |
| --detail                  | get, list     | Show detailed IME info                                              |
| --select-capable          | get, list     | Show only selectable IME                                            |
| --json                    | get, list     | Output as json text                                                 |
| --save                    | set           | Save current IME (with `macime set` only)                           |
| --session-id <session_id> | save, load    | Specify the save / load session id (= filename in temp dir)         |
| --launchd                 | (any)         | Indicate `called via launchd` (Ommit `[ERROR] ` prefix from stderr) |

Some unavailable options for each sub command will be simply ignored.


### macimed

`macimed` is bundled with `macime`.

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
Show the `macimed` status (running or stopped):
```bash
macimed --status
macimed -s
```
Output:
- `running` (exitcode=0)
- `stopped` (exitcode=1)

Show the `macimed` runtime info:
```bash
macimed --info
macimed -i
```
Output:
```txt
sock: /path/to/sock
status: running
macime: /path/to/macime
```
> [!Note]
> `tmp` path and `err`/`log` paths are controled by Homebrew, not by `macimed` itself.


#### macime Executable Path

`macimed` automatically detects the `macime` path from one of the following paths:
- `MACIME_PATH` (Environment variable)
- /usr/local/bin/macime (Homebrew on Intel Mac)
- /opt/homebrew/bin/macime (Homebrew on Apple Silicon)

The `MACIME_PATH` is set at `brew install` time via `macime.rb` in `riodelphino/homebrew-tap`:
```ruby
service do
  ...
  environment_variables(
    MACIME_PATH: opt_bin/"macime"
  )
  ...
end
```

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

Via `brew services` (Apple Intel):
* /usr/local/var/log/riodelphino/macimed.out.log
* /usr/local/var/log/riodelphino/macimed.err.log

Via `brew services` (Apple Silicon):
* /opt/homebrew/var/log/riodelphino/macimed.out.log
* /opt/homebrew/var/log/riodelphino.macimed.err.log

#### plist path via homebrew

path: ~/Library/LaunchAgents/homebrew.mxcl.macime.plist


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


## Issues

### Malformed array output with `--detail --json`

When using `--detail` together with `--json`, `macime` outputs array values as malformed JSON strings.

- Subcommands: `get`, `list`
- Options: `--detail --json`

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

## Others

**Deprecated**: `$MACIME_TEMP_DIR` environmental value in v3.0.0


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

