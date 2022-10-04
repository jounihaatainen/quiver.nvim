local locations = require("quiver.locations")
local ui = require("quiver.ui")

local M = {}

local default_options = {
  ui = {
    style = "minimal", -- Window style for picker window
    relative = "editor", -- Placement of picker window
    border = "rounded", -- Border style for picker window
    winhighlight = "Normal:Float", -- Window highlight to use in picker window
    wrap = false, -- Wrap lines in picker window
  }
}

M._quiver = {}
M._options = default_options

--- Set up quiver.
-- Sets up quiver for storing locations. Given values override default
-- values. Defaults are shown below:
--
-- require("quiver").setup {
--   ui = {
--     style = "minimal", -- Window style for picker window
--     relative = "editor", -- Placement of picker window
--     border = "rounded", -- Border style for picker window
--     winhighlight = "Normal:Float", -- Window highlight to use in picker window
--     wrap = false, -- Wrap lines in picker window
--   }
-- }
--
-- @param options The options for plugin. See above for default values.
function M.setup(options)
  M._options = vim.tbl_deep_extend("force", default_options, options or {})
  M._quiver = {}
end

--- Lists all locations added to the quiver.
function M.ls()
  if M._quiver == nil or #M._quiver == 0 then
    print('quiver: no locations in quiver')
    return
  end

  for i, location in ipairs(M._quiver) do
    print(i .. ": " .. location.file .. " (".. location.row .. ", " .. location.col .. ")")
  end
end

--- Add current cursor location to the quiver.
function M.add_current()
  locations.add_current_location(M._quiver)
end

--- Go to location in idx in the quiver.
-- @param idx Index of the location where to go.
function M.go(idx)
  -- assert(idx > 0 and idx <= #M._quiver, "There is no location in index " .. idx)
  if idx < 1 and idx > #M._quiver then
    error("quiver: there is no location in index " .. idx)
    return
  end

  locations.go_to_location(M._quiver, idx)
end

--- Clears all locations from the quiver.
function M.clear()
  table.clear(M._quiver)
end

--- Show picker for selecting location to go.
function M.pick()
  ui.pick_location(M._quiver, M.go, M._options)
end

return M
