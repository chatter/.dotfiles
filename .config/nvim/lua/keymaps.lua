local keybind = require('which-key').map_with_opts

-- :h mapleader
vim.g.mapleader = ','

-- :h map-commands
vim.keymap.set('i', 'jk', '<ESC>', { noremap = false, silent = true })
vim.keymap.set('n', '<C-j>', '<C-W><C-J>', { silent = true })
vim.keymap.set('n', '<C-k>', '<C-W><C-K>', { silent = true })
vim.keymap.set('n', '<C-l>', '<C-W><C-L>', { silent = true })
vim.keymap.set('n', '<C-h>', '<C-W><C-H>', { silent = true })
keybind({'n', 'v'}, '<leader>y', '"+y', { silent = true, desc = "Yank to system clipboard", icon = "" })
keybind({'n', 'v'}, '<leader>p', '"+p', { silent = true, desc = "Paste after (system clipboard)", icon = "↰" })
keybind({'n', 'v'}, '<leader>P', '"+P', { silent = true, desc = "Paste before (system clipboard)", icon = "↳" })
