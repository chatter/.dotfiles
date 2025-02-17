-- :h mapleader
vim.g.mapleader = ','

-- :h map-commands
vim.keymap.set('i', 'jk', '<ESC>', { noremap = false, silent = true })
vim.keymap.set('n', '<C-j>', '<C-W><C-J>', { silent = true })
vim.keymap.set('n', '<C-k>', '<C-W><C-K>', { silent = true })
vim.keymap.set('n', '<C-l>', '<C-W><C-L>', { silent = true })
vim.keymap.set('n', '<C-h>', '<C-W><C-H>', { silent = true })
vim.keymap.set('n', '<leader>y', '"+y', { silent = true })
vim.keymap.set('v', '<leader>y', '"+y', { silent = true })
vim.keymap.set('n', '<leader>p', '"+p', { silent = true })
vim.keymap.set('v', '<leader>p', '"+p', { silent = true })
vim.keymap.set('n', '<leader>P', '"+P', { silent = true })
vim.keymap.set('v', '<leader>P', '"+P', { silent = true })
