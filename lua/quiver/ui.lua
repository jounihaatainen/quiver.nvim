local locations = require("quiver.locations")

local M = {}

local buf, win

M._open_fn = function(idx)
  print("quiver: provide function for opening location in index " .. idx)
end

local function center(str)
  local width = vim.api.nvim_win_get_width(0)
  local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
  return string.rep(' ', shift) .. str
end

local function open_window(ui_options)
  buf = vim.api.nvim_create_buf(false, true) -- create new emtpy buffer

  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

  -- get dimensions
  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")

  -- calculate our floating window size
  local win_height = math.min(math.max(math.ceil(height * 0.25 - 4), 20), height)
  local win_width = math.min(math.max(math.ceil(width * 0.4), 40), width)

  -- and its starting position
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  local opts = {
    style = ui_options.style,
    relative = ui_options.relative,
    border = ui_options.border,
    width = win_width,
    height = win_height,
    row = row,
    col = col,
  }

  win = vim.api.nvim_open_win(buf, true, opts)

  vim.api.nvim_win_set_option(win, "wrap", ui_options.wrap)
  vim.api.nvim_win_set_option(win, "winhighlight", ui_options.winhighlight)
end

local function update_view(quiver)
  local msg = {}

  table.insert(msg, center("Quiver - Select location to go"))

  if quiver == nil or #quiver == 0 then
    table.insert(msg, "quiver: no locations in quiver")
  end

  for i, location in ipairs(quiver) do
    local line = " "

    if i < 10 then
      line = line .. " " .. i .. ": "
    elseif i == 10 then
      line = line .. " 0" .. ": "
    else
      line = line .. "    "
    end

    line = line .. location.file .. " (".. location.row .. ", " .. location.col .. ")"

    local preview = vim.api.nvim_buf_get_text(location.bufnr, location.row - 1, 0, location.row, -1, {})

    if preview then
      line = line .. " > " .. preview[1]
    end

    table.insert(msg, line)
  end

  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, msg)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

local function set_mappings(quiver)
  local mappings = {
    ["<cr>"] = "open_location_at_cursor()",
    ["<esc>"] = "close_window()",
    q = "close_window()",
    k = "move_cursor_up()",
    j = "move_cursor_down()",
    h = "move_location_up()",
    l = "move_location_down()",
  }

  for key, value in pairs(mappings) do
    vim.api.nvim_buf_set_keymap(buf, "n", key, ":lua require'quiver.ui'."..value.."<cr>", {
      nowait = true, noremap = true, silent = true
    })
  end

  for i, location in ipairs(quiver) do
    if i > 10 then
      break
    end

    vim.api.nvim_buf_set_keymap(buf, "n", ""..i, ":lua require'quiver.ui'.open_location(" .. i ..")<cr>", {
      nowait = true, noremap = true, silent = true
    })
  end

  local other_chars = {
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'm', 'n', 'o', 'p', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
  }

  for _, char in ipairs(other_chars) do
    vim.api.nvim_buf_set_keymap(buf, 'n', char, '', { nowait = true, noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', char:upper(), '', { nowait = true, noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', '<c-'..char..'>', '', { nowait = true, noremap = true, silent = true })
  end
end

function M.close_window()
  vim.api.nvim_win_close(win, true)
end

function M.move_cursor_up()
  local new_pos = math.max(2, vim.api.nvim_win_get_cursor(win)[1] - 1)
  vim.api.nvim_win_set_cursor(win, { new_pos, 0 })
end

function M.move_cursor_down()
  local line_count = vim.api.nvim_buf_line_count(buf)
  local new_pos = math.min(line_count, vim.api.nvim_win_get_cursor(win)[1] + 1)
  vim.api.nvim_win_set_cursor(win, { new_pos, 0 })
end

function M.move_location_up()
  local current_pos = vim.api.nvim_win_get_cursor(win)[1]
  local new_pos = math.max(2, current_pos - 1)

  if new_pos == current_pos then return end

  M._move_up_fn(current_pos, new_pos)
end

function M.move_location_down()
  local current_pos = vim.api.nvim_win_get_cursor(win)[1]
  local line_count = vim.api.nvim_buf_line_count(buf)
  local new_pos = math.min(line_count, vim.api.nvim_win_get_cursor(win)[1] + 1)

  if new_pos == current_pos then return end

  M._move_down_fn(current_pos, new_pos)
end

-- Open file under cursor
function M.open_location_at_cursor()
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  M.close_window()
  M._open_fn(row - 1)
end

-- Open file in position
function M.open_location(idx)
  M.close_window()
  M._open_fn(idx)
end

-- function M.pick_location(quiver, open_fn, move_up_fn, move_down_fn, remove_fn, options)
function M.pick_location(quiver, open_fn, options)
  M._open_fn = open_fn
  M._move_up_fn = function(current, new) end
  M._move_down_fn = function(current, new) end
  M._remove_fn = function(current, new) end
  open_window(options.ui)
  set_mappings(quiver)
  update_view(quiver)
  vim.api.nvim_win_set_cursor(win, { 2, 0 })
end

return M
