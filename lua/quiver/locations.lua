local M = {}

local function get_location(quiver, idx)
  return quiver[idx]
end

local function append_location(quiver, location)
  table.insert(quiver, location)
end

local function insert_location(quiver, idx, location)
  table.insert(quiver, idx, location)
end

local function remove_location(quiver, idx)
  table.remove(quiver, idx)
end

local function get_index_of(quiver, filename)
  for i, location in ipairs(quiver) do
    if location.file == filename then
      return i
    end
  end

  return nil
end

function M.add_current_location(quiver)
  local filename = vim.api.nvim_buf_get_name(0)
  local bufnr = vim.api.nvim_get_current_buf()
  local r, c = unpack(vim.api.nvim_win_get_cursor(0))
  local location = { file = filename, bufnr = bufnr, row = r, col = c }
  append_location(quiver, location)
end

function M.move_location(quiver, from, to)
  local location = get_location(quiver, from)
  remove_location(quiver, from)
  insert_location(quiver, to, location)
end

function M.move_current(quiver, to_idx)
  local current_filename = vim.api.nvim_buf_get_name(0)
  local from_idx = get_index_of(quiver, current_filename)

  if from_idx ~= nil then
    M.move_location(quiver, from_idx, to_idx)
  end
end

function M.remove_location(quiver, file_or_idx)
  if type(file_or_idx) == "string" then
    local idx = get_index_of(quiver, file_or_idx)
    remove_location(quiver, idx)
    return
  end

  remove_location(quiver, file_or_idx)
end

function M.go_to_location(quiver, idx)
  local location = get_location(quiver, idx)
  local ok, _ = pcall(vim.cmd, 'b ' .. location.file)

  if not ok then
    ok, _ = pcall(vim.cmd, 'e ' .. location.file)
  end

  if ok then
    vim.api.nvim_win_set_cursor(0, { location.row, location.col })
    return
  end

  error("quiver: file '" .. location.file .. "' (" .. location.row .. ", "
    .. location.col .. ") can't be opened")
end

return M
