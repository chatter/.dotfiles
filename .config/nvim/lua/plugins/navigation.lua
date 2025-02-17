local add, now = MiniDeps.add, MiniDeps.now

now(function()
  add(
    { source = 'MunsMan/kitty-navigator.nvim'
    , hooks = { post_install = function(t) os.execute("cp " .. t["path"] .. "/*.py ~/.config/kitty") end }
    }
  )
  require('kitty-navigator').setup(
    { keybindings =
      { left  = '<C-h>'
      , right = '<C-l>'
      , up    = '<C-k>'
      , down  = '<C-j>'
      }
    }
  )

  -- visual undolist, remove later if never used
  -- :UndotreeToggle
  add({ source = 'mbbill/undotree' })
end)
