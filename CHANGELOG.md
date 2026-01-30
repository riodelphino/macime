# CHANGELOG
## [3.3.1](https://github.com/riodelphino/macime/compare/v3.3.0...v3.3.1) (2026-01-31)

* **feat:** Add `--status` option (`macimed`)
* **docs:** Remove `Tips`
* **fix:** Reapply `.invalidOption` for `macimed`
* **refactor:** Change struct `Config` to enum `Defaults`

## [3.3.0](https://github.com/riodelphino/macime/compare/v3.2.2...v3.3.0) (2026-01-30)

* **docs:** Update `README.md`
* **chore:** Change `File` to `FS` (To avoid duprecation with Foundation's `FILE`)
* **feat:** Add `--info` option to `macimed`
* **docs:** Add Status badges
* **chore:** Change versions in `Package.swift`
* **fix:** Adapt to Apple Silicon's Homebrew bin directory (refer `MACIME_PATH` env)
* **fix:** Change the err/out log path via `brew services`
* **docs:** Add plist path

## [3.2.2](https://github.com/riodelphino/macime/compare/v3.2.1...v3.2.2) (2026-01-26)

* **docs:** Add an issue shows how to fix git conflict on tap repo
* **docs:** Refine `--launchd` option description and options table
* **docs:** Refine `Register as a launchd Service`

## [3.2.1](https://github.com/riodelphino/macime/compare/v3.2.0...v3.2.1) (2026-01-25)

* **fix:** Move elapsed time to the end of the log in `macimed`

## [3.2.0](https://github.com/riodelphino/macime/compare/v3.1.3...v3.2.0) (2026-01-25)

* **docs:** Add fallback command usage / Add macOS version requirements / Add issue about malformed json output / Refine
* **docs:** Clarify IME ID validation comments
* **fix:** `macime save` returns saved IME ID
* **fix:** Split response from `macime` into stdout/stderr in `macimed`
* **fix:** Prevent some subcommands from returning blank lines in `macime`
* **chore:** Change `SockError` to `IMEDError`
* **feat:** Supports fallback to `im-select-style` command usage (and refactoring)
* **refactor:** Swap the positions of ArgsIME and ArgsIMED 
* **refactor:** Rename functions / Refine comments in `IMED` / Others

## [3.1.2](https://github.com/riodelphino/macime/compare/v3.1.1...v3.1.2) (2026-01-24)

* **refactor:** Switch indent size from 4 to 3 again
* **refactor:** Migrate `log()` to `Log.swift`
* **refactor:** Rename struct & file for `macime` and `macimed` for better visibility
* **refactor:** Clean up comments
* **chore:** Remove/Refine comments and trash code
* **chore:** (Commented out -> Again) Add an error for `macime` not found

## [3.1.1](https://github.com/riodelphino/macime/compare/v3.1.0...v3.1.1) (2026-01-24)

* **fix:** `illegal hardware instruction` error on `ArgsDaemon` (`args[0]` cause error)
* **chore:** Add an error for `macime` not found
* **chore:** Remove unused `CmdSpec` struct
* **chore:** Remove unused `Response` struct
* **refactor:** Split common/macime/macimed Args operations / Enabled `macimed --help`
* **chore:** Update version
* **chore:** Add `--launchd` option / Refine `--session-id` arg operation / Colorize output
* **chore:** Refine some error messages
* **refactor:** Bundle `*Error` to `AppError`
* **docs:** Refine `macimed` description

## [3.1.0](https://github.com/riodelphino/macime/compare/v3.0.5...v3.1.0) (2026-01-24)

* **fix:** Rebuild error handling (Replace `Reasponse` to `throw`)
* **docs:** Add sock path

## [3.0.5](https://github.com/riodelphino/macime/compare/v3.0.4...v3.0.5) (2026-01-21)

* **docs:** Remove `doc/integration.md`
* **chore:** Remove `IO.outputJson()`
* **chore:** Respect locale on log/err datetime
* **chore:** Remove plist from `Package.swift`
* **chore:** Correct log/err path
* **chore:** Remove plist
* **docs:** Refine
* **docs:** macime is blazing faster!
* **docs:** Add log, err, tmp directories, and chore

## [3.0.4](https://github.com/riodelphino/macime/compare/v3.0.3...v3.0.4) (2026-01-21)

* **docs:** Fix upgradingx and launchd code examples
* **perf:** Use lazy loadings for struct properties

## [3.0.3](https://github.com/riodelphino/macime/compare/v3.0.2...v3.0.3) (2026-01-21)

* **chore:** Remove single-quote in `macimed` log
* **chore:** Show elapsed time in `macimed` log
* **refactor:** Replace `getInfo()` to flexible `describe()`
* **refactor:** Combine struct/enum into `Type.swift`
* **chore:** Add `config.macimePath`
* **docs:** Add command usage to restart launchd service

## [3.0.2](https://github.com/riodelphino/macime/compare/v3.0.1...v3.0.2) (2026-01-20)

* **chore:** Common versioning
* **chore:** Remove unnecessary excutables
* **docs:** Refine / Add log and err path for `macimed`
* **chore:** `processCommand()` func returns response.content without `\n` or `OK\n`
* **chore:** Update the version info
* **fix:** set sub-command returns Response
* **fix:** log() shows `OK` when status.ok in `macimed`
* **revert:** Swap log and err output in `macimed`
* **fix:** Swap log and err output in `macimed`
* **refactor:** processCommand() comments

## [3.0.1](https://github.com/riodelphino/macime/compare/v3.0.0...v3.0.1) (2026-01-20)

* **fix:** Use full path for calling `macime` from `macimed`

## [3.0.0](https://github.com/riodelphino/macime/compare/v2.3.0...v3.0.0) (2026-01-20)

* **feat!:** BREAKING CHANGE! Add launchd service wrapper `macimed`
* **chore:** `$MACIME_TEMP_DIR` is deprecated
* **fix:** Parsing args error with `--session-id <session_id>` on `macimed`
* **fix** Deprecate output json directory (Output json as string instead)

## [2.3.0](https://github.com/riodelphino/macime/compare/v2.2.6...v2.3.0) (2026-01-18)

* **feat:** Add `macime save` sub command
* **docs:** Refine `README.md`
* **docs:** Reformat `CHANGELOG.md`

## [2.2.6](https://github.com/riodelphino/macime/compare/v2.2.5...v2.2.6) (2026-01-11)

* **docs:** Move an issue to `macime.nvim`
* **fix:** Refactor help
* **fix:** Change `macime --version` to return `2.2.6` (not `macime v2.2.6`)

## [2.2.5](https://github.com/riodelphino/macime/compare/v2.2.4...v2.2.5) (2026-01-10)

* **chore:** Update version in command to 2.2.5

## [2.2.4](https://github.com/riodelphino/macime/compare/v2.2.3...v2.2.4) (2026-01-10)

* **docs:** Add `--help` option to `README.md`

## [2.2.3](https://github.com/riodelphino/macime/compare/v2.2.2...v2.2.3) (2026-01-10)

* **docs:** Add `--help` option
* **feat:** Use `MACIME_TEMP_DIR` environment variable if exists
* **fix:** Change dir `/tmp/riodelphino.macime/prev` to  `/tmp/riodelphino.macime`

## [2.2.2](https://github.com/riodelphino/macime/compare/v2.2.1...v2.2.2) (2026-01-09)

* **docs:** Add contributions to `README.md`
* **docs:** Chore in `README.md`

## [2.2.1](https://github.com/riodelphino/macime/compare/v2.2.0...v2.2.1) (2026-01-09)

* **fix:** Some fixes for `brew install`

## [2.2.0](https://github.com/riodelphino/macime/compare/v2.1.0...v2.2.0) (2026-01-09)

* **refactor:** Optimize the file structure
* **build:** Enable `swift build`
* **feat:** Enable installing with `brew`
* **chore:** Remove `cocoa`

## [2.1.0](https://github.com/riodelphino/macime/compare/v2.0.2...v2.1.0) (2026-01-08)

* **chore:** Add error handling
* **docs:** Split Neovim sample code into `integration.md`
* **refactor:** Restructure the entire code
* **fix:** Fix `path not exists` error by creating temporary dir if not exists
* **docs:** Add `azookey` caution to `README.md`

## [2.0.2](https://github.com/riodelphino/macime/compare/v2.0.1...v2.0.2) (2026-01-08)

* **docs:** Add `macime.nvim` plugin to `README.md`
* **fix:** Fix `--version` to return version

## [2.0.1](https://github.com/riodelphino/macime/compare/v2.0.0...v2.0.1) (2026-01-08)

* **fix:** Remove unused `--show` option completely
* **docs:** Reine `README.md`
* **docs:** Add `LICENSE`
* **docs:** Change `CHANGELOG` filetype to markdown

## [2.0.0](https://github.com/riodelphino/macime/compare/v1.0.3...v2.0.0) (2026-01-07)

* **feat:** Totally modified & refactored from `v1.x`
* **feat:** Add sub-commands
* **feat:** Save previous IME in `/tmp` dir

