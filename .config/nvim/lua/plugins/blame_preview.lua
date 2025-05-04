-- lua/blame_preview.lua

local M = {}

local blame_ns = vim.api.nvim_create_namespace("blame_hash_links")
local buf_roles = {}
local last_known_line = {}

function M.set_buffer_role(buf, role)
  if buf and vim.api.nvim_buf_is_valid(buf) then
    buf_roles[buf] = role
  end
end

function M.underline_blame_hashes(buf)
  vim.api.nvim_buf_clear_namespace(buf, blame_ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  for i, line in ipairs(lines) do
    local hash = line:match("^(%w+)")
    if hash then
      vim.api.nvim_buf_add_highlight(buf, blame_ns, "Underlined", i - 1, 0, #hash:sub(1, 7))
    end
  end
end

function M.replace_source_with_commit(hash, file)
  local source_buf
  for buf, role in pairs(buf_roles) do
    if role == "source" and vim.api.nvim_buf_is_valid(buf) then
      source_buf = buf
      break
    end
  end

  if not source_buf then
    vim.notify("No source buffer found to replace", vim.log.levels.WARN)
    return
  end

  if vim.bo[source_buf].modified then
    local choice = vim.fn.confirm("Buffer modified. Replace with commit version and lose changes?", "&Yes\n&No", 2)
    if choice ~= 1 then return end
  end

  local content = vim.fn.systemlist({ "git", "show", hash .. ":" .. file })
  if vim.v.shell_error ~= 0 or not content or #content == 0 then
    vim.notify("Failed to get file at commit", vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_buf_set_lines(source_buf, 0, -1, false, content)
  vim.bo[source_buf].modified = false
end

function M.open_floating_commit_diff(hash, file, orig_line)
  local blame_win = vim.api.nvim_get_current_win()
  local blame_cursor = vim.api.nvim_win_get_cursor(blame_win)

  local output = vim.fn.systemlist({ "git", "show", hash, "--", file })

  if vim.v.shell_error ~= 0 or not output or #output == 0 then
    vim.notify("No diff available", vim.log.levels.INFO)
    return
  end

  local target_line = 0
  for i = #output, 1, -1 do
    local hunk = output[i]
    local start, count = hunk:match("^@@ %-%d+,%d+ %+([%d]+),([%d]+) @@")
    if not start then
      start = hunk:match("^@@ %-%d+ %+([%d]+) @@")
      count = "1"
    end

    local s, c = tonumber(start), tonumber(count)
    if s and c and orig_line and orig_line >= s and orig_line <= (s + c - 1) then
      target_line = i - 1
      break
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, output)
  vim.bo[buf].filetype = "diff"
  vim.bo[buf].modifiable = false

  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.6)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  })

  vim.api.nvim_win_set_cursor(win, { target_line + 1, 0 })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(0, true)
    pcall(vim.api.nvim_win_set_cursor, blame_win, blame_cursor)
  end, { buffer = buf, nowait = true })

  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = buf,
    once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
        pcall(vim.api.nvim_win_set_cursor, blame_win, blame_cursor)
      end
    end,
  })
end

function M.setup_enter_mapping()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "git",
    callback = function()
      local buf = vim.api.nvim_get_current_buf()

      vim.keymap.set("n", "<Tab>", function()
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        row = row - 1

        local marks = vim.api.nvim_buf_get_extmarks(buf, blame_ns, { row, 0 }, { row, -1 }, { details = true })

        for _, mark in ipairs(marks) do
          local _, _, mark_col, details = unpack(mark)
          local start_col = mark_col
          local end_col = details and details.end_col

          if start_col and end_col and col >= start_col and col < end_col then
            local line = vim.api.nvim_get_current_line()
            local hash = line:match("^(%w+)")
            local file = vim.fn.expand("#:~:.")
            local orig_line = row + 1
            M.open_floating_commit_diff(hash, file, orig_line)
            return
          end
        end
      end, { buffer = buf, desc = "Preview commit diff" })

      vim.keymap.set("n", "<CR>", function()
        local row = vim.api.nvim_win_get_cursor(0)[1] - 1
        local line = vim.api.nvim_get_current_line()
        local hash = line:match("^(%w+)")
        if not hash then return end
        local file = vim.fn.expand("#:~:.")
        M.replace_source_with_commit(hash, file)
      end, { buffer = buf, desc = "Replace source buffer with commit version" })
    end,
  })
end

function M.compact_left_blame(au_data)
  if au_data.data.git_subcommand ~= "blame" then return end

  local win_src = au_data.data.win_source
  local buf_src = win_src and vim.api.nvim_win_get_buf(win_src)
  local buf_blame = vim.api.nvim_get_current_buf()

  if buf_src then M.set_buffer_role(buf_src, "source") end
  M.set_buffer_role(buf_blame, "blame")

  local lines = vim.api.nvim_buf_get_lines(buf_blame, 0, -1, false)

  local trimmed = vim.tbl_map(function(line)
    local hash, meta = line:match("^(%w+)%s+%((.+)%)")
    if hash and meta then
      local author, date = meta:match("^(.-)%s+(%d%d%d%d%-%d%d%-%d%d)")
      if author and date then
        author = vim.trim(author)
        return string.format("%s %-14s %s", hash:sub(1, 7), author, date)
      end
    end
    return line
  end, lines)

  vim.api.nvim_buf_set_lines(buf_blame, 0, -1, false, trimmed)
  M.underline_blame_hashes(buf_blame)

  vim.wo.wrap = false
  vim.api.nvim_win_set_width(0, 30)
  vim.fn.winrestview({ topline = vim.fn.line("w0", win_src) })
  vim.api.nvim_win_set_cursor(0, { vim.fn.line(".", win_src), 0 })
  vim.wo[win_src].scrollbind = true
  vim.wo.scrollbind = true
end

vim.api.nvim_create_autocmd("WinLeave", {
  callback = function()
    local win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_config(win).relative ~= "" then return end
    local buf = vim.api.nvim_get_current_buf()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    last_known_line[buf] = line
  end,
})

vim.api.nvim_create_autocmd("WinEnter", {
  callback = function()
    local cur_win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_config(cur_win).relative ~= "" then return end

    local cur_buf = vim.api.nvim_get_current_buf()
    local cur_role = buf_roles[cur_buf]

    if not cur_role then
      local ft = vim.bo[cur_buf].filetype
      if ft == "git" then
        cur_role = "blame"
      elseif vim.bo[cur_buf].buftype == "" then
        cur_role = "source"
      end
      M.set_buffer_role(cur_buf, cur_role)
    end

    if cur_role ~= "source" and cur_role ~= "blame" then return end

    local other_role = cur_role == "source" and "blame" or "source"
    local other_buf = nil

    for buf, role in pairs(buf_roles) do
      if role == other_role and vim.api.nvim_buf_is_valid(buf) then
        other_buf = buf
        break
      end
    end

    if not other_buf then return end

    local remembered = last_known_line[other_buf]
    if remembered then
      local max = vim.api.nvim_buf_line_count(cur_buf)
      local target = math.min(remembered, max)
      pcall(vim.api.nvim_win_set_cursor, cur_win, { target, 0 })
    end
  end,
})

return M
