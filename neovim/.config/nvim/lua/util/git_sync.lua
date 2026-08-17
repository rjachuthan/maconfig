local icons = require("core.icons")

local M = {}

--- How long a cached result stays fresh before the next statusline redraw
--- kicks off another `git status` call.
local TTL_MS = 5000

---@class GitSyncState
---@field ahead integer
---@field behind integer
---@field dirty boolean
---@field upstream boolean
---@field checked integer
---@field running boolean

---@type table<string, GitSyncState>
local cache = {}

---@param root string
---@return GitSyncState
local function state_of(root)
  cache[root] = cache[root] or { ahead = 0, behind = 0, dirty = false, upstream = false, checked = 0, running = false }
  return cache[root]
end

--- Parse `git status --porcelain=v2 --branch` output.
---@param out string
---@param state GitSyncState
local function parse(out, state)
  state.ahead, state.behind, state.dirty, state.upstream = 0, 0, false, false
  for line in vim.gsplit(out, "\n", { plain = true }) do
    if line:sub(1, 1) == "#" then
      local ahead, behind = line:match("^# branch%.ab %+(%d+) %-(%d+)")
      if ahead then
        state.ahead, state.behind, state.upstream = tonumber(ahead), tonumber(behind), true
      end
    elseif line ~= "" then
      state.dirty = true
    end
  end
end

---@param root string
local function refresh(root)
  local state = state_of(root)
  if state.running then
    return
  end
  state.running = true
  state.checked = vim.uv.now()

  vim.system(
    { "git", "-C", root, "--no-optional-locks", "status", "--porcelain=v2", "--branch", "--untracked-files=no" },
    { text = true },
    function(res)
      state.running = false
      local before = { state.ahead, state.behind, state.dirty, state.upstream }
      if res.code == 0 then
        parse(res.stdout or "", state)
      else
        state.ahead, state.behind, state.dirty, state.upstream = 0, 0, false, false
      end
      -- Only redraw when something actually changed; an unconditional redraw on
      -- every poll makes the git components flicker.
      if
        before[1] ~= state.ahead
        or before[2] ~= state.behind
        or before[3] ~= state.dirty
        or before[4] ~= state.upstream
      then
        vim.schedule(function()
          vim.cmd.redrawstatus()
        end)
      end
    end
  )
end

---@param root string
---@return GitSyncState
local function get(root)
  local state = state_of(root)
  if not state.running and vim.uv.now() - state.checked > TTL_MS then
    refresh(root)
  end
  return state
end

--- Drop cached results so the next lookup re-runs `git status`.
function M.invalidate()
  for _, state in pairs(cache) do
    state.checked = 0
  end
end

---@return string
local function root()
  return require("util.root").get(vim.api.nvim_get_current_buf())
end

--- `true` when the working tree of the current buffer's repo has changes that
--- are not committed yet (tracked files only).
---@return boolean
function M.dirty()
  return get(root()).dirty
end

--- Commits waiting to be pulled/pushed, rendered as ` 3↓ 1↑`. Empty when the
--- branch has no upstream or is fully in sync.
---@return string
function M.status()
  local state = get(root())
  if not state.upstream or (state.ahead == 0 and state.behind == 0) then
    return ""
  end
  return table.concat({
    icons.git.sync,
    state.behind,
    icons.git.behind,
    " ",
    state.ahead,
    icons.git.ahead,
  })
end

--- Append the VSCode-style `*` marker to a branch name when the tree is dirty.
---@param branch string
---@return string
function M.branch(branch)
  if branch == "" then
    return branch
  end
  return branch .. (M.dirty() and icons.git.dirty or "")
end

local augroup = vim.api.nvim_create_augroup("nvim_util_git_sync", { clear = true })

vim.api.nvim_create_autocmd({ "BufWritePost", "FocusGained", "DirChanged" }, {
  group = augroup,
  callback = M.invalidate,
  desc = "Refresh git ahead/behind counts",
})

vim.api.nvim_create_autocmd("User", {
  group = augroup,
  pattern = { "FugitiveChanged", "GitSignsUpdate" },
  callback = M.invalidate,
  desc = "Refresh git ahead/behind counts after git operations",
})

return M
