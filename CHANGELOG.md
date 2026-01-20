# CHANGELOG

## [3.0.2](https://github.com/riodelphino/macime/compare/v3.0.1...v3.0.2) (2026-01-20)

* **docs:** Refine / Add log and err path for `macimed`
* **fix:** Swap log and err output on `macimed`
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

