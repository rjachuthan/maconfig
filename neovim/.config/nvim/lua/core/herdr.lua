--- Inside Herdr, .excalidraw files open in Herdr's own Excalidraw tab (the `excalidraw` mod)
--- instead of the system app. Everything else (Excel, PDFs, ...) keeps opening as before.
--- Snacks explorer's `o` goes through vim.ui.open, so it picks this up; so does `gx`.
local M = {}

local function in_herdr()
  return (vim.env.HC_TERMINAL_SOCKET or vim.env.HERDR_ENV) and vim.fn.executable("herdr-app") == 1
end

local function is_diagram(path)
  return path:match("%.excalidraw$") or path:match("%.excalidraw%.json$")
end

--- Open (or create, on first save) a diagram as a Herdr tab.
---@param path string
---@return vim.SystemObj
function M.open_diagram(path)
  local file = vim.fn.fnamemodify(path, ":p"):gsub("\\", "/")
  local args = vim.json.encode({ name = vim.fn.fnamemodify(file, ":t"), mod = "excalidraw", props = { file = file } })
  return vim.system({ "herdr-app", "do", "tab.new", args }, { text = true }, function(r)
    if r.code ~= 0 then
      vim.schedule(function()
        vim.notify("Herdr couldn't open the diagram: " .. vim.trim(r.stderr ~= "" and r.stderr or r.stdout), vim.log.levels.ERROR)
      end)
    end
  end)
end

function M.setup()
  if not in_herdr() then return end
  local system_open = vim.ui.open
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.ui.open = function(path, opt)
    if type(path) == "string" and not path:match("^%a[%w+.-]*://") and is_diagram(path) then
      return M.open_diagram(path), nil
    end
    return system_open(path, opt)
  end

  vim.api.nvim_create_user_command("Excalidraw", function(o)
    local path = o.args ~= "" and o.args or vim.api.nvim_buf_get_name(0)
    if path == "" then return vim.notify("Excalidraw: give a file name", vim.log.levels.WARN) end
    if not is_diagram(path) then path = path .. ".excalidraw" end
    M.open_diagram(path)
  end, { nargs = "?", complete = "file", desc = "Open or create an Excalidraw diagram in Herdr" })
end

return M
