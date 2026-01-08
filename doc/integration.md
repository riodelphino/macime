## Integration

### Neovim

Direction:
- In `InsertLeave` event: Set `com.apple.keylayout.ABC` while auto saving current IME. 
- In `InsertEnter` event: Restore the saved previous IME.

> [!Note]
> All the following code are included in [riodelphino/macime.nvim](https://github.com/riodelphino/macime.nvim) plugin.


#### Simple setup

Save IME ID into a single common file `/tmp/riodelphino.macime/prev/DEFAULT`.  
(Works fine in most cases.)

* Use `macime set <IME_ID> --save` to save
* Use `macime load` to restore it

init.lua:
```lua
vim.api.nvim_create_autocmd('InsertLeave', {
   callback = function()
      vim.fn.jobstart({ 'macime', 'set', 'com.apple.keylayout.ABC', '--save' })
   end,
})
vim.api.nvim_create_autocmd('InsertEnter', {
   callback = function()
      vim.fn.jobstart({ 'macime', 'load' })
   end,
})
```

#### Robust setup

Use this setup when you feel wierd in [#simple-setup](#simple-setup), or you switch `nvim` instance so often.

Save into a separated file per nvim's process id. (e.g. `/tmp/riodelphino.macime/prev/nvim-<pid>`)  
This manages previous IME independently.

* Use `macime set --save --session-id nvim-<pid>` to save into a separated file.
* Use `macime load --session-id nvim-<pid>` to restore it.

init.lua:
```lua
vim.api.nvim_create_autocmd('InsertLeave', {
   callback = function()
      local session_id = 'nvim-' .. vim.fn.getpid()
      vim.fn.jobstart({ 'macime', 'set', 'com.apple.keylayout.ABC', '--save', '--session-id', session_id })
   end,
})
vim.api.nvim_create_autocmd('InsertEnter', {
   callback = function()
      local session_id = 'nvim-' .. vim.fn.getpid()
      vim.fn.jobstart({ 'macime', 'load', '--session-id', session_id })
   end,
})
```

#### Exclude Specific Filetypes

Exclude specific filetypes from auto saving/restoring.

init.lua:
```lua
vim.api.nvim_create_autocmd('InsertLeave', {
   callback = function()
      vim.fn.jobstart({ 'macime', 'set', 'com.apple.keylayout.ABC', '--save' })
   end,
})
vim.api.nvim_create_autocmd('InsertEnter', {
   callback = function()
      local exclude_list = { 'TelescopePrompt', 'snacks_picker_input' }
      local filetype = vim.bo.filetype
      local is_allowed_filetype = not vim.tbl_contains(exclude_list, filetype)
      if is_allowed_filetype then vim.fn.jobstart({ 'macime', 'load' }) end
   end,
})
```

