local add = MiniDeps.add

add(
  { source = 'nvim-treesitter/nvim-treesitter'
  , hooks = { post_checkout = function() vim.cmd('TSUpdate') end }
  } 
)
require('nvim-treesitter.configs').setup(
  { ensure_installed = { 'elixir', 'eex', 'heex' }
  , highlight = { enable = true }
  }
)
