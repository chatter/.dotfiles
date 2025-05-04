local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

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

later(function()
  add(
    { source = 'folke/flash.nvim'
    , depends = { 'nvim-treesitter/nvim-treesitter' }
    , hooks =
      { post_checkout = function()
          vim.cmd('TSUpdate')
        end
      }
    }
  )

  require('flash').setup(
    { modes =
      { search = { enabled = true }
      , char =
        { enabled = true
        , keys = { 'f', 'F', 't', 'T' }
        }
      }
    }
  )

  local map = vim.keymap.set
  local flash = function(fn)
    return function()
      require("flash")[fn]()
    end
  end

  map({ "n", "x", "o" }, "s", flash("jump"), { desc = "Flash" })
  map({ "n", "x", "o" }, "S", flash("treesitter"), { desc = "Flash Treesitter" })
  map("o", "r", flash("remote"), { desc = "Remote Flash" })
  map({ "o", "x" }, "R", flash("treesitter_search"), { desc = "Treesitter Search" })
  map("c", "<C-s>", flash("toggle"), { desc = "Toggle Flash Search" })

  vim.keymap.set("n", "*",
    function()
      require("flash").jump({ pattern = vim.fn.expand("<cword>") })
    end,
    { desc = "Flash search for word under cursor" }
  )

  vim.keymap.set("n", "#",
    function()
      require("flash").jump(
        { pattern = vim.fn.expand("<cword>")
        , search = { forward = false, wrap = true }
        }
      )
    end,
    { desc = "Flash search backward for word under cursor" }
  )
end)
