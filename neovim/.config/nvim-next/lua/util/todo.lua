local M = {}

---@param opts { forward: boolean }
local function jump(opts)
  local todo = require("todo-comments")
  if opts.forward then
    todo.jump_next()
  else
    todo.jump_prev()
  end
end

local repeatable ---@type fun(opts: { forward: boolean })

--- Jump to the next/previous todo comment, repeatable with `;` and `,` when
--- nvim-treesitter-textobjects is available.
---@param opts { forward: boolean }
function M.jump(opts)
  if not repeatable then
    local ok, move = pcall(require, "nvim-treesitter-textobjects.repeatable_move")
    repeatable = ok and move.make_repeatable_move(jump) or jump
  end
  repeatable(opts)
end

return M
