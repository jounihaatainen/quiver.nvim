local file_utils = require("quiver.file_utils")

local M = {}

M._locations = {}
M._open_fn = function(idx)
  print("quiver: provide function for opening location in index " .. idx)
end
M._move_location_fn = function(from_index, to_index)
  print("quiver: provide function for moving location from index " .. from_index .. " to index " .. to_index)
end
M._remove_location_fn = function(index)
  print("quiver: provide function for removing location from index " .. index)
end

local buf, win, prev_guicursor

local function center(str)
  local width = vim.api.nvim_win_get_width(0)
  local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
  return string.rep(' ', shift) .. str
end

local function index2row(index)
  return index + 1
end

local function row2index(winpos)
  return winpos - 1
end

local function set_options(window, buffer, ui_options)
  vim.api.nvim_set_hl(0, "QuiverWindowCursor", { reverse = true, blend = 100 })

  vim.api.nvim_win_set_option(window, "winhl", "Normal:Normal")
  vim.api.nvim_win_set_option(window, "cursorline", true)

  if ui_options.wrap ~= nil then
    vim.api.nvim_win_set_option(win, "wrap", ui_options.wrap)
  end

  -- guicursor needs to be set globally
  -- save original value and add autocmd to return it after user leaves the window
  prev_guicursor = vim.go.guicursor
  vim.api.nvim_set_option("guicursor", "a:QuiverWindowCursor")

  local augroup = vim.api.nvim_create_augroup("QuiverWindowAugroup", {})
  vim.api.nvim_create_autocmd({ "WinLeave" }, {
    buffer = buffer,
    callback = function()
      vim.go.guicursor = prev_guicursor
      vim.api.nvim_del_augroup_by_id(augroup)
    end,
    group = augroup,
  })
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

  set_options(win, buf, ui_options)
end

local function get_buf_if_loaded(fname)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local buf_fname = vim.api.nvim_buf_get_name(bufnr)

    if fname == buf_fname and vim.api.nvim_buf_is_loaded(bufnr) then
      return bufnr
    end
  end

  return -1
end

local function get_preview(fname, row)
 local bufnr = get_buf_if_loaded(fname)

  if bufnr >= 0 then
    return vim.api.nvim_buf_get_text(bufnr, row - 1, 0, row - 1, -1, {})
  end

  -- if vim.fn.filereadable(fname) > 0 then
  --   return vim.fn.systemlist({ "sed" , row .. "!d ", fname })
  -- end
  --
  -- return { "<file is missing>" }
 return file_utils.get_rows(fname, row, 3, "<file is missing>")
end

local function format_location(location)
  local str = file_utils.shorten_file_path(location.file) .. " (".. location.row .. ", " .. location.col .. ")"
  local preview = get_preview(location.file, location.row)

  if preview ~= nil and #preview > 0 then
    str = str .. " > " .. preview[1]
  end

  return str
end

local function update_view(locations)
  local msg = {}

  table.insert(msg, center("Quiver - Select location to go"))

  if locations == nil or #locations == 0 then
    table.insert(msg, "quiver: no locations in quiver")
  end

  for i, location in ipairs(locations) do
    local line = " "

    if i < 10 then
      line = line .. " " .. i .. ": "
    elseif i == 10 then
      line = line .. " 0" .. ": "
    else
      line = line .. "    "
    end

    line = line .. format_location(location)
    table.insert(msg, line)
  end

  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, msg)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

local action_to_command_map = {
  open_location = "open_location_at_cursor()",
  open_location_in_vertical_split = "open_location_at_cursor({ open_in_split = 'vertical' })",
  open_location_horizontal_split = "open_location_at_cursor({ open_in_split = 'horizontal' })",
  close_window = "close_window()",
  move_cursor_down = "move_cursor(1)",
  move_cursor_up = "move_cursor(-1)",
  move_location_down = "move_location_on_cursor(1)",
  move_location_up = "move_location_on_cursor(-1)",
  remove_location = "remove_location_at_cursor()",
}

local function get_keys_for_commands(keys_for_actions)
  local keys_for_commands = {}

  for action, key_object in pairs(keys_for_actions) do
    local keys = key_object

    if type(key_object) == "string" then
      keys = { key_object }
    end

    for _, key in ipairs(keys) do
      keys_for_commands[key] = action_to_command_map[action]
    end
  end

  return keys_for_commands
end

local function set_mappings(locations, keys_for_actions)
  local keys_for_commands = get_keys_for_commands(keys_for_actions)

  for key, command in pairs(keys_for_commands) do
    vim.api.nvim_buf_set_keymap(buf, "n", key, ":lua require'quiver.ui'."..command.."<cr>", {
      nowait = true, noremap = true, silent = true
    })
  end

  for i, _ in ipairs(locations) do
    if i > 10 then
      break
    end

    vim.api.nvim_buf_set_keymap(buf, "n", ""..i, ":lua require'quiver.ui'.open_location(" .. i ..")<cr>", {
      nowait = true, noremap = true, silent = true
    })
  end

  local all_chars = {
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
  }

  for _, char in ipairs(all_chars) do
    if keys_for_commands[char] == nil then
      vim.api.nvim_buf_set_keymap(buf, 'n', char, '', { nowait = true, noremap = true, silent = true })
    end
    if keys_for_commands[char:upper()] == nil then
      vim.api.nvim_buf_set_keymap(buf, 'n', char:upper(), '', { nowait = true, noremap = true, silent = true })
    end
    if keys_for_commands["<c-"..char..">"] == nil then
      vim.api.nvim_buf_set_keymap(buf, 'n', '<c-'..char..'>', '', { nowait = true, noremap = true, silent = true })
    end
  end
end

local function adjust_row_of_location_under_cursor(row_change)
  local current_row = vim.api.nvim_win_get_cursor(win)[1]
  local line_count = vim.api.nvim_buf_line_count(buf)
  return current_row, math.max(2, math.min(current_row + row_change, line_count))
end

function M.close_window()
  vim.api.nvim_win_close(win, true)
end

function M.move_cursor(row_change)
  local _, new_row = adjust_row_of_location_under_cursor(row_change)
  vim.api.nvim_win_set_cursor(win, { new_row, 0 })
end

function M.move_location_on_cursor(row_change)
  row_change = row_change or 1

  local current_row, new_row = adjust_row_of_location_under_cursor(row_change)
  local current_index = row2index(current_row)
  local new_index = row2index(new_row)

  if new_index == current_index then return end

  M._move_location_fn(current_index, new_index)

  update_view(M._locations)
  M.move_cursor(row_change)
end

function M.remove_location_at_cursor()
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local index = row2index(row)

  M._remove_location_fn(index)

  update_view(M._locations)
end

--- Open file under cursor
function M.open_location_at_cursor(opts)
  opts = opts or {}
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  M.close_window()
  M._open_fn(row2index(row))
end

--- Open file in position
function M.open_location(idx)
  M.close_window()
  M._open_fn(idx)
end

function M.pick_location_in_float(locations, open_fn, move_location_fn, remove_location_fn, ui_options)
  M._locations = locations
  M._open_fn = open_fn
  M._move_location_fn = move_location_fn
  M._remove_location_fn = remove_location_fn
  open_window(ui_options)
  set_mappings(locations, ui_options.keys_for_actions)
  update_view(locations)
  vim.api.nvim_win_set_cursor(win, { index2row(1), 0 })
end

function M.pick_location(locations, open_fn)
  vim.ui.select(locations, {
    prompt = "Select location to go:",
    format_item = function(loc)
      return format_location(loc, 72)
    end,
  }, function(_, idx)
    open_fn(idx)
  end)
end

return M
