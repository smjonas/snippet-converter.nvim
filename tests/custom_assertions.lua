local M = {}

local function ends_with(_, arguments)
  return arguments[2]:sub(-#arguments[1]) == arguments[1]
end

local function matches_snippet(_, arguments)
  local expected, actual, options = arguments[1], arguments[2], arguments[3]
  local same_name = expected.name == actual.name
  local same_trigger = expected.trigger == actual.trigger
  local same_description = expected.description == actual.description
  local same_body_length = expected.body_length == #actual.body
  local same_options = expected.options == actual.options

  local same_path = expected.path == actual.path
  local same_line_nr = (options and options.ignore_line_nr and true) or expected.line_nr == actual.line_nr
  local same_priority = expected.priority == actual.priority
  local same_custom_context = expected.custom_context == actual.custom_context

  return same_name
    and same_trigger
    and same_description
    and same_options
    and same_body_length
    and same_path
    and same_line_nr
    and same_priority
    and same_custom_context
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

  say:set("assertion.matches_snippet.positive", "Expected snippet to match %s\n but got %s")
  assert:register("assertion", "matches_snippet", matches_snippet, "assertion.matches_snippet.positive")
end

return M
