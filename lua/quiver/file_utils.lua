local M = {}

---Shortens given file path `file_path`
---@param file_path string
---@return string
function M.shorten_file_path(file_path)
  file_path = vim.fn.simplify(file_path)
  local user_home = os.getenv("HOME")

  if user_home ~= nil then
    file_path = file_path:gsub(user_home, "~")
  end

  return vim.fn.pathshorten(file_path)
end

---Create directory (and intermitten directories) if they don't exits
---@param directory any
function M.ensure_directory_exists(directory)
  if vim.fn.isdirectory(directory) == 0 then
    vim.fn.mkdir(directory, "p")
  end
end

---Get `n_rows` rows starting from row `start_row` from file `fname`. Display optional error message
--`file_is_missing_msg` if file is missing.
---@param fname string Filename
---@param start_row number First row to get
---@param n_rows number Number of rows to get (default is 1)
---@param file_is_missing_msg string Return value (only item in array) if file is missing (default is "")
---@return string[]
function M.get_rows(fname, start_row, n_rows, file_is_missing_msg)
  n_rows = n_rows or 1
  file_is_missing_msg = file_is_missing_msg or ""

  if n_rows < 1 then
    error("cannot get less than 1 row from file")
  end

  local end_row = start_row + n_rows - 1

  if vim.fn.filereadable(fname) > 0 then
    return vim.fn.systemlist({ "sed" , "-n", start_row .. "," .. end_row .. "p", fname})
  end

  return { file_is_missing_msg }
end

return M
