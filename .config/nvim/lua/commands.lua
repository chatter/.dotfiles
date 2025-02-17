-- Similar to Vim's DiffOrig command
vim.api.nvim_create_user_command('DiffOrig', function()
    vim.cmd("vert new | set buftype=nofile | read ++edit # | 0d_ | diffthis | wincmd p | diffthis")
end, {})
