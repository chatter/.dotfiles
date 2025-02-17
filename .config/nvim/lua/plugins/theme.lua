local add, now = MiniDeps.add, MiniDeps.now

now(function()
  add(
    { source = 'folke/tokyonight.nvim'
    , hooks =
        { post_install = function(t)
            function copy_themes(src, dst)
              local s = t["path"] .. "/extras/" .. src .. "/*"
              local d = "~/.config/" .. dst .. "/themes"
              os.execute("mkdir -p " .. d .. " && cp " .. s .. " " .. d)
            end

            copy_themes("kitty", "kitty")
            copy_themes("fish_themes", "fish")
          end
        }
    }
  )
  require('tokyonight').setup(
    { dim_inactive = true
    , on_highlights = function(hl, c)
        hl.LineNr = { fg = c.orange, bold = false }
        hl.CursorLineNr = { fg = c.orange, bold = true }
        hl.LineNrAbove = { fg = c.fg_dark }
        hl.LineNrBelow = { fg = c.fg_dark }
      end
    }
  )
  vim.cmd.colorscheme('tokyonight')
end)
