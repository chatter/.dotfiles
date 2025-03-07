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

  vim.api.nvim_create_autocmd('LspAttach',
    { desc = 'LSP actions'
    , callback = function(event)
        local opts = { buffer = event.buf }

        vim.keymap.set('n',        'K',    '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
        vim.keymap.set('n',        'gd',   '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
        vim.keymap.set('n',        'gD',   '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
        vim.keymap.set('n',        'gi',   '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
        vim.keymap.set('n',        'go',   '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
        vim.keymap.set('n',        'gr',   '<cmd>lua vim.lsp.buf.references()<cr>', opts)
        vim.keymap.set('n',        'gs',   '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
        vim.keymap.set('n',        '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
        vim.keymap.set({'n', 'x'}, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
        vim.keymap.set('n',        'ca', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
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
    { ensure_installed = { 'vtsls', 'gopls', 'prettierd' }
    , handlers =
      { function(server_name)
          require('lspconfig')[server_name].setup({})
        end
      , ['vtsls'] = function()
          require('lspconfig').vtsls.setup(
            { settings = { completions = { completeFunctionCalls = true } } 
            }
          )
        end
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
