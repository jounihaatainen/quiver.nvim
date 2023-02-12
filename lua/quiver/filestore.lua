local M = {}

local function ensure_directory_exists(directory)
  if vim.fn.isdirectory(directory) == 0 then
    vim.fn.mkdir(directory, "p")
  end
end

local function trim(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function save(locations, fname)
  fname = vim.fn.expand(fname)

  local lines = {}

  for _, loc in ipairs(locations) do
    table.insert(lines, loc.file .. "|" .. loc.row .. "|" .. loc.col)
  end

  vim.fn.writefile(lines, fname)
end

local function load(fname)
  fname = vim.fn.expand(fname)

  if vim.fn.filereadable(fname) == 0 then
    print("quiver: data file " .. fname .. " is not readable")
    return {}
  end

  local lines = vim.fn.readfile(fname, "")

  if #lines == 0 then
    return {}
  end

  local locations = {}

  for _, line in ipairs(lines) do
    line = trim(line)

    if line ~= "" then
      local matcher = string.gmatch(line, "([^|]+)")
      local filename = matcher()
      local row = tonumber(matcher())
      local col = tonumber(matcher())

      if filename ~= nil and row ~= nil and col ~= nil then
        local location = { file = filename, row = row, col = col }
        table.insert(locations, location)
      end
    end
  end

  return locations
end

local function ensure_default_options_exist(opts)
  opts = opts or {}

  if opts.data_dir == nil then
    opts.data_dir = vim.fn.stdpath("data") .. "/quiver"
  end

  if opts.filename == nil then
    opts.filename = "locations.json"
  end

  return opts
end

--- Save locations in to a file
-- Defaults for options are:
--
-- require("quiver.filestore").save {
--   data_dir = vim.fn.stdpath("data") .. "/quiver/",
--   filename = "locations.json",
-- }
--
-- @param options The options for saving locations. See above for default values.
function M.save(locations, opts)
  opts = ensure_default_options_exist(opts)
  ensure_directory_exists(opts.data_dir)
  save(locations, vim.fn.resolve(opts.data_dir .. "/" .. opts.filename))
end

--- Load locations from a file
-- Defaults for options are:
--
-- require("quiver.filestore").load {
--   data_dir = vim.fn.stdpath("data") .. "/quiver/",
--   filename = "locations.json",
-- }
--
-- @param options The options for loading locations. See above for default values.
function M.load(opts)
  opts = ensure_default_options_exist(opts)
  return load(vim.fn.resolve(opts.data_dir .. "/" .. opts.filename))
end

return M
