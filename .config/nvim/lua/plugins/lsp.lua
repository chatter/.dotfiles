local add, now = MiniDeps.add, MiniDeps.now

now(function()
  add({ source = 'neovim/nvim-lspconfig' })

  add(
    { source = 'hrsh7th/nvim-cmp'
    , depends =
      { 'hrsh7th/cmp-nvim-lsp'
      , 'hrsh7th/cmp-buffer'
      }
    }
  )

  add({ source = 'onsails/lspkind.nvim' })

  add(
    { source = 'L3MON4D3/LuaSnip'
    , checkout = 'v2.3.0'
    , depends =
      { 'rafamadriz/friendly-snippets'
      , 'saadparwaiz1/cmp_luasnip'
      }
    , hooks =
        { post_install = function(t)
            os.execute('cd ' .. t['path'] .. ' && make install_jsregexp')
          end
        }
    }
  )
  require('luasnip.loaders.from_vscode').lazy_load()

  local cmp = require('cmp')
  local lspkind  = require('lspkind')
  local luasnip = require('luasnip')

  cmp.setup(
    { sources = cmp.config.sources(
      { { name = 'luasnip' }
      , { name = 'nvim_lsp' }
      , { name = 'buffer' }
      })
    , preselect = cmp.PreselectMode.None
    , snippet =
      { expand = function(args)
          luasnip.lsp_expand(args.body)
        end
      }
    , mapping = cmp.mapping.preset.insert(
      { ["<CR>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            if luasnip.expandable() then
              luasnip.expand()
            else
              cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true })
            end
          else
            fallback()
          end
        end)
      , ["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert })
      , ["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
      , ["<C-l>"] = cmp.mapping(function(fallback)
          if luasnip.locally_jumpable(1) then
            if cmp.visible() then
              cmp.close()
            end
            luasnip.jump(1)
          else
            fallback()
          end
        end, { "i", "s" })

      , ["<C-h>"] = cmp.mapping(function(fallback)
          if luasnip.locally_jumpable(-1) then
            if cmp.visible() then
              cmp.close()
            end
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" })
      })
    , experimental =
      { ghost_text = true }
    , formatting =
      { format = lspkind.cmp_format(
          { mode = 'symbol_text'
          , menu =
            { buffer = "[buf]"
            , nvim_lsp = "[lsp]"
            , luasnip = "[snp]"
            }
          , maxwidth =
            { menu = 50
            , abbr = 50
            }
          , ellipsis_char = '…'
          , show_labelDetails = true
          }
        )
      }
    , window =
      { completion = cmp.config.window.bordered()
      , documentation = cmp.config.window.bordered()
      }
    }
  )

  local lspconfig_defaults = require('lspconfig').util.default_config
  lspconfig_defaults.capabilities = vim.tbl_deep_extend(
    'force', lspconfig_defaults.capabilities, require('cmp_nvim_lsp').default_capabilities()
  )

  -- global fallback: shows message if no LSP is attached
  vim.keymap.set("n", "<leader>ca", function()
    vim.notify("LSP not attached in this buffer.", vim.log.levels.WARN)
  end, { desc = "Code Action (LSP not attached)" })

  vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
  })

  vim.o.updatetime = 500
  vim.api.nvim_create_autocmd("CursorHold", {
    callback = function()
      local line = vim.api.nvim_win_get_cursor(0)[1] - 1
      local diags = vim.diagnostic.get(0, { lnum = line })
      if #diags > 0 then
        vim.defer_fn(function()
          vim.diagnostic.open_float(nil, { focusable = false, border = "rounded" })
        end, 100)  -- small delay to let diagnostics update
      end
    end,
  })

  vim.api.nvim_create_autocmd('LspAttach',
    { desc = 'LSP actions'
    , callback = function(event)
        local keybind = require('which-key').map_with_opts
        keybind('n', '<leader>ca', vim.lsp.buf.code_action,       { buffer = event.buf, desc = 'Code Action',           icon = ''  })
        keybind('n', '<leader>cr', vim.lsp.buf.rename,            { buffer = event.buf, desc = 'Rename Symbol',         icon = '✎'  })
        keybind('n', '<leader>ch', vim.lsp.buf.hover,             { buffer = event.buf, desc = 'Hover Info',            icon = ''  })
        keybind('n', '<leader>cs', vim.lsp.buf.signature_help,    { buffer = event.buf, desc = 'Signature Help',        icon = ''  })
        keybind('n', '<leader>cd', vim.lsp.buf.definition,        { buffer = event.buf, desc = 'Go to Definition',      icon = ''  })
        keybind('n', '<leader>cD', vim.lsp.buf.declaration,       { buffer = event.buf, desc = 'Go to Declaration',     icon = ''  })
        keybind('n', '<leader>ci', vim.lsp.buf.implementation,    { buffer = event.buf, desc = 'Go to Implementation',  icon = ''  })
        keybind('n', '<leader>ct', vim.lsp.buf.type_definition,   { buffer = event.buf, desc = 'Go to Type Definition', icon = ''  })
        keybind('n', '<leader>cR', vim.lsp.buf.references,        { buffer = event.buf, desc = 'Find References',       icon = ''  })
        keybind('n', '<leader>cn', vim.diagnostic.goto_next,      { buffer = event.buf, desc = 'Next Diagnostic',       icon = ''  })
        keybind('n', '<leader>cp', vim.diagnostic.goto_prev,      { buffer = event.buf, desc = 'Previous Diagnostic',   icon = ''  })
        keybind('n', '<leader>cl', vim.diagnostic.setloclist,     { buffer = event.buf, desc = 'Diagnostics (Loclist)', icon = ''  })
        keybind('n', '<leader>cf', function()
          vim.lsp.buf.format({ async = true })
        end,                                                            { desc = 'Format Buffer',         icon = ''  }) -- paintbrush
      end
    }
  )

  add(
    { source = 'williamboman/mason.nvim'
    , depends = { 'williamboman/mason-lspconfig.nvim' }
    }
  )
  require('mason').setup()
  require('mason-lspconfig').setup(
    { ensure_installed = { 'denols', 'vtsls', 'gopls', 'elixirls' }
    , handlers =
      { function(server_name)
          require('lspconfig')[server_name].setup({})
        end
      , ['denols'] = function()
          require('lspconfig').denols.setup({ root_dir = require('lspconfig').util.root_pattern 'deno.json' })
        end
      , ['vtsls'] = function()
          require('lspconfig').vtsls.setup({
            single_file_support = false,
            root_dir = function()
              return not vim.fs.root(0, { 'deno.json', 'deno.jsonc' })
                and vim.fs.root(0, { 'tsconfig.json', 'package.json', 'jsconfig.json', 'bun.lockb', '.git' })
            end,
          })
        end
      -- , ['vtsls'] = function()
      --     require('lspconfig').vtsls.setup(
      --       { settings = { completions = { completeFunctionCalls = true } } 
      --       }
      --     )
      --   end
      , ['gopls'] = function()
          require('lspconfig').gopls.setup(
            { on_attach = function(_client, _buf)
                vim.api.nvim_create_autocmd("BufWritePre",
                { pattern = { "*.go" }
                , callback = function()
                    local params = vim.lsp.util.make_range_params()
                    params.context = { only = { "source.organizeImports" } }
                    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params)
                    for cid, res in pairs(result or {}) do
                      for _, r in pairs(res.result or {}) do
                        if r.edit then
                          local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
                          vim.lsp.util.apply_workspace_edit(r.edit, enc)
                        end
                      end
                    end
                    vim.lsp.buf.format({async = false})
                  end
                })
              end
            , settings =
              { gopls =
                { analyses =
                  { unusedparams = true
                  }
                , usePlaceholders = true
                , staticcheck = true
                , gofumpt = true
                }
              }
            }
          )
        end
      }
    }
  )
end)

