local primitives = {}

primitives.pattern = function(_pattern)
  return function(input)
    local match = input:match("^" .. _pattern)
    if match ~= nil then
      return match, input:sub(match:len() + 1), match
    end
  end
end

primitives.bind = function(capture_identifier, parser_fn)
  return {
    capture_identifier = capture_identifier,
    parser_fn = parser_fn,
  }
end

local parse = function(parser, input)
  if type(parser) == "table" then
    return true, parser.parser_fn(input)
  else
    return false, parser(input)
  end
end

primitives.either = function(parsers)
  return function(input)
    local match, new_remainder, captures, should_capture, sub_captures
    for _, parser in ipairs(parsers) do
      should_capture, match, new_remainder, sub_captures = parse(parser, input)
      if match ~= nil then
        if should_capture then
          captures = {
            [parser.capture_identifier] = sub_captures
          }
        end
        return match, new_remainder, captures
      end
    end
  end
end

primitives.all = function(parsers)
  return function(input)
    local match, new_match, new_remainder, captures, should_capture, sub_captures
    local remainder = input
    for _, parser in ipairs(parsers) do
      should_capture, new_match, new_remainder, sub_captures = parse(parser, remainder)
      if new_match == nil then
        return nil
      else
        if should_capture then
          if captures == nil then
            captures = {}
          end
          captures[parser.capture_identifier] = sub_captures
        end
        match = (match or "") .. new_match
        remainder = new_remainder
      end
    end
    return match, remainder, captures
  end
end

-- TODO: replace vim.join with table.concat everywhere
primitives.at_least = function(amount, parser)
  return function(input)
    local should_capture, match, remainder, _ = parse(parser, input)
    local new_remainder
    local captures

    local matches = { match }
    local total_matches = #matches
    while match ~= nil and remainder ~= "" do
      _, match, new_remainder, _ = parse(parser, remainder)
      if match ~= nil then
        remainder = new_remainder
        total_matches = total_matches + 1
        matches[total_matches] = match
      end
    end

    if amount == 0 and total_matches == 0 then
      return "", input, captures
    end

    if total_matches >= amount then
      local joined_matches = table.concat(matches)
      if should_capture then
        captures = {
          [parser.capture_identifier] = joined_matches
        }
      end
      return joined_matches, remainder, captures
    end
  end
end

return primitives
