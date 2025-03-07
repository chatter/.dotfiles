local add, now = MiniDeps.add, MiniDeps.now

now(function()
  add({ source = 'stevearc/conform.nvim' })
  add({ source = 'zapling/mason-conform.nvim' })

  conform = require('conform')

  conform.setup(
    { formatters_by_ft =
      { javascript  = { 'prettierd' }
      , typescript  = { 'prettierd' }
      , html        = { 'prettierd' }
      , htmlangular = { 'prettierd' }
      , json        = { 'prettierd' }
      , css         = { 'prettierd' }
      }
    }
  , { format_on_save =
      { lsp_fallback = true
      , async = false
      , timeout_ms = 500
      }
    }
  )

  vim.keymap.set(
    { "n", "v" }
  , "<leader>mp"
  , function()
      conform.format(
        { lsp_fallback = true
        , async = false
        , timeout_ms = 500
        }
      )
    end
  , { desc = "Format file or range (in visual mode)" }
  )

  vim.api.nvim_create_autocmd(
    "BufWritePre"
  , { pattern = "*"
    , callback = function(args)
        conform.format({ bufnr = args.buf })
      end
    }
  )

  require('mason-conform').setup()
end)
