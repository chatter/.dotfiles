local add, now = MiniDeps.add, MiniDeps.now

now(function()
  add({ source = 'folke/which-key.nvim' })
  local wk = require('which-key')
  wk.setup()
  wk.add(
    { { "<leader>c", group = "code" }
    , { "<leader>f", group = "file" }
    , { "<leader>g", group = "git" }
    , { "<leader>s", group = "search" }
    }
  )

  function wk.map_with_opts(mode, lhs, rhs, opts)
    wk.add({ lhs, rhs, desc = opts.desc, icon = opts.icon, mode = mode, buffer = opts.buffer })
  end
end)
