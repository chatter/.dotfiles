local now = MiniDeps.now
local later = MiniDeps.later

now(function() require('mini.diff').setup() end)
now(function() require('mini.extra').setup() end)
now(function() require('mini.git').setup() end)
now(function() require('mini.icons').setup() end)
now(function() require('mini.statusline').setup() end)
-- now(function() require('mini.surround').setup() end)

local function recent_files_in_cwd()
  local cwd = vim.fn.fnamemodify(vim.loop.cwd(), ':p')

  local cwd = vim.fn.fnamemodify(vim.loop.cwd(), ":p")

  -- Step 1: Filter valid, in-project files
  local filtered = vim.tbl_filter(function(path)
    local full = vim.fn.fnamemodify(path, ":p")
    return vim.fn.filereadable(full) == 1 and full:sub(1, #cwd) == cwd
  end, vim.v.oldfiles)

  -- Step 2: Map to relative paths
  local files = vim.tbl_map(function(path)
    local full = vim.fn.fnamemodify(path, ":p")
    return full:sub(#cwd + 1)
  end, filtered)

  require('mini.pick').start({
    source = { items = files },
    action = "edit",
  })
end

later(
  function()
    local mp = require('mini.pick')
    mp.setup(
      { mappings =
          { move_down = '<C-n>'
          , move_up = '<C-p>'
          }
      }
    )

    local keybind = require('which-key').map_with_opts
    keybind("n", "<leader>ff", function() mp.builtin.files() end, { desc = "Find File", icon = "" })
    keybind("n", "<leader>fr", recent_files_in_cwd, { desc = "Recent Files", icon = ""})
    keybind("n", "<leader>fb", function() mp.builtin.buffers() end, { desc = "Open Buffers", icon = ""})
    keybind("n", "<leader>fs", "<cmd>w<cr>", { desc = "Save File", icon = "" })
    keybind("n", "<leader>fS", "<cmd>wa<cr>", { desc = "Save All Files", icon = "" })
    keybind("n", "<leader>fd", "<cmd>bd<cr>", { desc = "Delete Buffer", icon = "" })
    keybind("n", "<leader>fe", function()  vim.cmd.edit(vim.fn.expand("%:p:h")) end, { desc = "Browse File Dir", icon = "" })

    keybind("n", "<leader>fne", "<cmd>enew<cr>",  { desc = "New File",           icon = "" })
    keybind("n", "<leader>fnvh", "<cmd>leftabove vnew<cr>",  { desc = "New File (VSplit Left)",  icon = "↤" })
    keybind("n", "<leader>fnvl", "<cmd>rightbelow vnew<cr>",  { desc = "New File (VSplit Right)",  icon = "↦" })
    keybind("n", "<leader>fnhk", "<cmd>leftabove new<cr>",   { desc = "New File (HSplit Above)",   icon = "↥" })
    keybind("n", "<leader>fnhj", "<cmd>rightbelow new<cr>",   { desc = "New File (HSplit Below)",   icon = "↧" })

    keybind("n", "<leader>f/", function() mp.builtin.grep_live() end, { desc = "Search Files",   icon = "" })

    keybind("n", "<leader>fR", function()
      if vim.bo.modified then
        local choice = vim.fn.confirm("Buffer modified. Reload and lose changes?", "&Yes\n&No", 2)
        if choice ~= 1 then return end
        vim.cmd("edit!")
      end
      vim.cmd.edit()
    end, {
      desc = "Reload File",
      icon = "",
    })

    keybind("n", "<leader>fx", function()
      local file = vim.api.nvim_buf_get_name(0)
      if file == "" or vim.fn.filereadable(file) == 0 then
        vim.notify("No file to delete", vim.log.levels.WARN)
        return
      end

      local confirm = vim.fn.confirm("Really delete file?\n" .. file, "&Yes\n&No", 2)
      if confirm ~= 1 then return end

      vim.fn.delete(file)
      vim.cmd.bdelete()
      vim.notify("💀 File deleted. Rest in bits.", vim.log.levels.INFO)
    end, {
      desc = "Delete File",
      icon = "☠︎",
    })

    keybind("n", "<leader>f.", function()
      local file = vim.api.nvim_buf_get_name(0)
      if file == "" then
        vim.notify("No file to reveal", vim.log.levels.WARN)
        return
      end

      local dir = vim.fn.fnamemodify(file, ":p:h")
      local open_cmd

      if vim.fn.has("macunix") == 1 then
        open_cmd = { "open", dir }
      elseif vim.fn.has("win32") == 1 then
        open_cmd = { "explorer", dir }
      else
        open_cmd = { "xdg-open", dir }
      end

      vim.fn.jobstart(open_cmd, { detach = true })
    end, {
      desc = "Reveal in File Manager",
      icon = "󰍹",
    })

    -- mini.git stuff (mostly for blame)
    local blame_preview = require('plugins.blame_preview')

    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniGitCommandSplit",
      callback = blame_preview.compact_left_blame,
    })

    blame_preview.setup_enter_mapping()

    -- mini.git keybinds
    keybind("n", "<leader>ga",  "<cmd>Git add %<CR>", { desc = "Add current file", icon = "" })
    keybind("n", "<leader>gA", "<cmd>Git add --all<CR>", { desc = "Add all files", icon = "" })
    keybind("n", "<leader>gb",  "<cmd>leftabove vertical Git blame -- %<cr>", { desc = "Blame", icon = "󰛢" })
    keybind("n", "<leader>gc",  "<cmd>Git commit<CR>", { desc = "Commit changes", icon = "" })
    keybind("n", "<leader>gC", "<cmd>Git commit --amend<CR>", { desc = "Amend last commit", icon = "󰷈" })
    keybind("n", "<leader>gr", function()
      local file = vim.fn.expand("%")
      local confirm = vim.fn.confirm("Restore '" .. file .. "' from HEAD?\nThis will discard all changes.", "&Yes\n&No", 2)

      if confirm == 1 then
        vim.fn.system({ "git", "restore", "--", file })
        vim.cmd("edit!") -- Reload the file in buffer
        vim.notify("🔄 Restored " .. file .. " from HEAD", vim.log.levels.INFO)
      else
        vim.notify("Restoration cancelled", vim.log.levels.INFO)
      end
    end, {
      desc = "Restore current file (discard changes)",
      icon = "",
    })


    -- BEGIN: TODO REFACTOR
    local line_history_ns = vim.api.nvim_create_namespace("line_history_links")

    local function underline_commit_hashes(buf)
      vim.api.nvim_buf_clear_namespace(buf, line_history_ns, 0, -1)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      for i, line in ipairs(lines) do
        local hash = line:match("^commit (%w+)")
        if hash then
          local start_col = line:find(hash)
          if start_col then
            vim.api.nvim_buf_add_highlight(buf, line_history_ns, "Underlined",
              i - 1, start_col - 1, start_col - 1 + #hash)
          end
        end
      end
    end

    local function handle_commit_hash_enter(buf, file)
      return function()
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        row = row - 1

        local marks = vim.api.nvim_buf_get_extmarks(buf, line_history_ns, { row, 0 }, { row, -1 }, {
          details = true,
        })

        for _, mark in ipairs(marks) do
          local _, _, mark_col, details = unpack(mark)
          local end_col = details and details.end_col

          if mark_col and end_col and col >= mark_col and col < end_col then
            local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
            local hash = line:match("^commit (%w+)")
            local orig_line = vim.api.nvim_win_get_cursor(0)[1]
            blame_preview.open_floating_commit_diff(hash, file, orig_line)
            break
          end
        end
      end
    end

    local function show_line_history_float()
      local file = vim.fn.expand("%:.")
      local cursor = vim.api.nvim_win_get_cursor(0)[1]

      local output = vim.fn.systemlist({ "git", "log", "-L", cursor .. "," .. cursor .. ":" .. file })

      if vim.v.shell_error ~= 0 or not output or #output == 0 then
        vim.notify("No line history available", vim.log.levels.INFO)
        return
      end

      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
      vim.bo[buf].filetype = "git"
      vim.bo[buf].modifiable = false

      local width  = math.floor(vim.o.columns * 0.6)
      local height = math.floor(vim.o.lines * 0.6)

      local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width    = width,
        height   = height,
        row      = math.floor((vim.o.lines - height) / 2),
        col      = math.floor((vim.o.columns - width) / 2),
        style    = "minimal",
        border   = "rounded",
      })

      -- q to close
      vim.keymap.set("n", "q", function()
        vim.api.nvim_win_close(0, true)
      end, { buffer = buf, nowait = true })

      -- close on focus loss
      vim.api.nvim_create_autocmd("WinLeave", {
        buffer = buf,
        once = true,
        callback = function()
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
        end,
      })

      vim.keymap.set("n", "<CR>", handle_commit_hash_enter(buf, file), {
        buffer = buf,
        nowait = true,
        desc = "Preview commit diff"
      })

      underline_commit_hashes(buf)
      return buf
    end

    keybind("n", "<leader>gl", function()
      show_line_history_float()
    end, {
      desc = "Line history (float)",
      icon = "󰋚",
    })
    -- END: TODO REFACTOR

  end
)

