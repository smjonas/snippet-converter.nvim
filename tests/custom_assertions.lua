local M = {}

local function ends_with(_, arguments)
  return arguments[2]:sub(-#arguments[1]) == arguments[1]
end

M.register = function(assert)
  local say = require("say")
  say:set("assertion.ends_with.positive", 'Expected string to end with "%s": "%s"')
  say:set("assertion.ends_with.negative", 'Expected string to not end with "%s": "%s"')
  assert:register(
    "assertion",
    "ends_with",
    ends_with,
    "assertion.ends_with.positive",
    "assertion.ends_with.negative"
  )
end

return M
