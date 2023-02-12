local locations = require("quiver.locations")
local ui = require("quiver.ui")

local M = {}

local default_options = {
  ui = {
    style = "minimal",                       -- Window style for picker window
    relative = "editor",                     -- Placement of picker window
    border = "rounded",                      -- Border style for picker window
    wrap = false,                            -- Wrap lines in picker window
    keys_for_actions = {
      open_location = "<cr>",                -- Key(s) to open location under cursor
      open_location_in_vertical_split = "v", -- Key(s) to open location under cursor in vertical split
      open_location_horizontal_split = "s",  -- Key(s) to open location under cursor in horizontal split
      close_window = { "<esc>", "q" },       -- Key(s) to close window without opening any location
      move_cursor_down = "j",                -- Key(s) to move selection cursor down
      move_cursor_up = "k",                  -- Key(s) to move selection cursor up
      move_location_down = "d",              -- Key(s) to move location under cursor up
      move_location_up = "u",                -- Key(s) to move location under cursor down
      remove_location = "x",                 -- Key(s) to remove location under selection from list of locations
    },
 },
 store = {
   load = function() return require("quiver.filestore").load() end,
   save = function(locs) require("quiver.filestore").save(locs) end,
 },
}

M._locations = {}
M._loaded = false
M._options = default_options

function M._load_if_needed()
  if M._loaded == false then
    M._locations = M._options.store.load()
  end
  M._loaded = true
end

function M._save()
  M._options.store.save(M._locations)
end

function M._move_and_save(from_index, to_index)
  locations.move_location(M._locations, from_index, to_index)
  M._save()
end

function M._clear_locations()
  M._locations = {}
end

--- Set up quiver.
-- Sets up quiver for storing locations. Given values override default
-- values. Defaults are shown below:
--
-- require("quiver").setup {
--   ui = {
--     style = "minimal",                       -- Window style for picker window
--     relative = "editor",                     -- Placement of picker window
--     border = "rounded",                      -- Border style for picker window
--     wrap = false,                            -- Wrap lines in picker window
--     keys_for_actions = {
--       open_location = "<cr>",                -- Key(s) to open location under cursor
--       open_location_in_vertical_split = "v", -- Key(s) to open location under cursor in vertical split
--       open_location_horizontal_split = "s",  -- Key(s) to open location under cursor in horizontal split
--       close_window = { "<esc>", "q" },       -- Key(s) to close window without opening any location
--       move_cursor_down = "j",                -- Key(s) to move selection cursor down
--       move_cursor_up = "k",                  -- Key(s) to move selection cursor up
--       move_location_down = "d",              -- Key(s) to move location under cursor up
--       move_location_up = "u",                -- Key(s) to move location under cursor down
--       remove_location = "x",                 -- Key(s) to remove location under selection from list of locations
--     },
--  },
--  store = {
--    load = function() return require("quiver.filestore").load() end,
--    save = function(locs) require("quiver.filestore").save(locs) end,
--  },
-- }
--
-- @param options The options for plugin. See above for default values.
function M.setup(options)
  M._options = vim.tbl_deep_extend("force", default_options, options or {})
  M._locations = {}
end

--- Lists all locations added to the quiver.
function M.ls()
  M._load_if_needed()

  if M._locations == nil or #M._locations == 0 then
    print('quiver: no locations in quiver')
    return
  end

  for i, location in ipairs(M._locations) do
    print(i .. ": " .. location.file .. " (".. location.row .. ", " .. location.col .. ")")
  end
end

--- Add current cursor location to the quiver.
function M.add_current()
  locations.add_current_location(M._locations)
  M._save()
end

--- Remove location in index from quiver.
function M.remove(index)
  locations.remove_location(M._locations, index)
  M._save()
end

--- Go to location in idx in the quiver.
--
-- For example go to location in index 1:
--
-- require("quiver").go(1, {
--   center_to_window = false, -- center location to window (default false)
-- })
--
-- @param idx Index of the location where to go.
-- @param opts Options for going to the location. Not required.
function M.go(idx, opts)
  opts = opts or {}

  M._load_if_needed()

  if idx == nil then
    print("quiver: can not go to nil selection")
    return
  end

  if idx < 1 or idx > #M._locations then
    print("quiver: there is no location in index " .. idx)
    return
  end

  locations.go_to_location(M._locations, idx, opts)
end

--- Clears all locations from the quiver.
function M.clear()
  M._clear()
  M._save()
end

--- Show picker for selecting location to go.
function M.pick(opts)
  opts = opts or {}

  M._load_if_needed()

  ui.pick_location(M._locations, function(index)
    if index == nil then return end
    M.go(index)
  end)
end

--- Show floating picker for selecting location to go.
--
-- For example show floating picker for selecting a location
--
-- require("quiver").pick_in_float({
--   center_to_window = false, -- center location to window (default false)
-- })
--
-- @param opts Options for going to the location. Not required.
function M.pick_in_float(opts)
  opts = opts or {}

  M._load_if_needed()

  ui.pick_location_in_float(
    M._locations,
    function(index) M.go(index, opts) end,
    function(from_index, to_index) M._move_and_save(from_index, to_index) end,
    function(index) M.remove(index) end,
    M._options.ui)
end

return M
