local now = MiniDeps.now
local later = MiniDeps.later

now(function() require('mini.diff').setup() end)
now(function() require('mini.extra').setup() end)
now(function() require('mini.git').setup() end)
now(function() require('mini.icons').setup() end)
now(function() require('mini.statusline').setup() end)
now(function() require('mini.surround').setup() end)

later(
  function()
    require('mini.pick').setup(
      { mappings =
          { move_down = '<C-j>'
          , move_up = '<C-k>'
          }
      }
    )
    vim.keymap.set('n', '<C-p>', ':Pick files<CR>', { silent = true })
    vim.keymap.set('n', '<D-p>', ':Pick grep_live<CR>', { silent = true })
  end
)
