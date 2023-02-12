local M = {}

local function get_location(locations, idx)
  return locations[idx]
end

local function location_exists(locations, location)
  for _, loc in ipairs(locations) do
    if loc.file == location.file and loc.row == location.row then
      return true
    end
  end
  return false
end

local function append_location(locations, location)
  table.insert(locations, location)
end

local function insert_location(locations, idx, location)
  table.insert(locations, idx, location)
end

local function remove_location(locations, idx)
  table.remove(locations, idx)
end

local function get_index_of(locations, filename)
  for i, location in ipairs(locations) do
    if location.file == filename then
      return i
    end
  end

  return nil
end

function M.add_location(locations, fname, row, col)
  local location = { file = fname, row = row, col = col }
  if not location_exists(locations, location) then
    append_location(locations, location)
  end
end

function M.add_current_location(locations)
  local filename = vim.api.nvim_buf_get_name(0)

  if filename == nil or filename == "" then
    print("quiver: can't add non-file buffers")
    return
  end

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  M.add_location(locations, filename, row, col)
end

function M.move_location(locations, from, to)
  local location = get_location(locations, from)
  remove_location(locations, from)
  insert_location(locations, to, location)
end

function M.move_current(locations, to_idx)
  local current_filename = vim.api.nvim_buf_get_name(0)
  local from_idx = get_index_of(locations, current_filename)

  if from_idx ~= nil then
    M.move_location(locations, from_idx, to_idx)
  end
end

function M.remove_location(locations, file_or_idx)
  if type(file_or_idx) == "string" then
    local idx = get_index_of(locations, file_or_idx)
    remove_location(locations, idx)
    return
  end

  remove_location(locations, file_or_idx)
end

local function open_in_original_window_if_visible(location)
  local windows = vim.api.nvim_list_wins()

  for _, win in ipairs(windows) do
    local buf = vim.api.nvim_win_get_buf(win)
    local fname = vim.api.nvim_buf_get_name(buf)

    if fname == location.file then
      vim.api.nvim_set_current_win(win)
      vim.api.nvim_win_set_cursor(win, { location.row, location.col })
      return true
    end
  end

  return false
end

local function open_location_with(location, vim_commands_or_functions)
  if type(vim_commands_or_functions) ~= "table" then
    vim_commands_or_functions = { vim_commands_or_functions }
  end

  for _, cmd_or_fun in ipairs(vim_commands_or_functions) do
    local func = cmd_or_fun

    if type(cmd_or_fun) == "string" then
      func = function(loc)
        vim.cmd(cmd_or_fun .. " " .. loc.file)
        vim.api.nvim_win_set_cursor(0, { loc.row, loc.col })
      end
    elseif type(cmd_or_fun) ~= "function" then
      error("Error: Executing unsupported " .. type(cmd_or_fun))
    end

    local ok, ret_val = pcall(func, location)

    if ok and type(ret_val) == "boolean" and ret_val == true then
      return true
    end
    if ok and type(ret_val) ~= "boolean" then
      return true
    end
  end

  return false
end

function M.go_to_location(locations, idx, opts)
  opts = vim.tbl_deep_extend("force", { center_to_window = false }, opts or {})

  local location = get_location(locations, idx)

  if opts.open_in_split == "horizontal" and open_location_with(location, "split") then
    return
  end

  if opts.open_in_split == "vertical" and open_location_with(location, "vsplit") then
    return
  end

  if open_location_with(location, { function(file) return open_in_original_window_if_visible(file) end, "b", "e" }) then
    if opts.center_to_window == true then
      vim.api.nvim_feedkeys("zz", "m", false)
    end
    return
  end

  error("quiver: file '" .. location.file .. "' (" .. location.row .. ", " .. location.col .. ") can't be opened")
end

return M
