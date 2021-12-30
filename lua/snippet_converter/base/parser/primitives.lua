local primitives = {}

primitives.pattern = function(_pattern)
  return function(input)
    local match = input:match("^" .. _pattern)
    if match ~= nil then
      return match, input:sub(match:len() + 1), match
    end
  end
end

local parse = function(parser, input)
  if type(parser) == "table" then
    return true, parser.parser_fn(input)
  else
    return false, parser(input)
  end
end

local parse_and_capture = function(parser, input, captures)
  local match, remainder
  if type(parser) == "table" then
    local sub_captures
    match, remainder, sub_captures = parser.parser_fn(input)
    print("IN PA")
      print(vim.inspect(match))
      print(vim.inspect(remainder))
      print(vim.inspect(sub_captures))
    if match == nil then
      return nil
    end
    if sub_captures ~= nil then
      if captures == nil then
        captures = {
          [parser.capture_identifier] = sub_captures
        }
      else
        captures[parser.capture_identifier] = sub_captures
      end
    end
    print(3)
    print(vim.inspect(captures))
    return match, remainder, captures
  else
    match, remainder, _ = parser(input)
    print(34)
    return match, remainder, captures
  end
end

primitives.bind = function(capture_identifier, parser_fn)
  local parser = {
    capture_identifier = capture_identifier,
    parser_fn = parser_fn,
  }
  -- Allow calling parser table as a function
  setmetatable(parser, { __call = function(_, input)
    local match, remainder, captures = parse_and_capture(parser, input, nil)
    return match, remainder, {
      [capture_identifier] = captures
    }
  end})
  return parser
end

primitives.either = function(parsers)
  return function(input)
    local match, remainder, captures
    for _, parser in ipairs(parsers) do
      match, remainder, captures = parse_and_capture(parser, input, nil)
      print("IN EITHER")
      print(vim.inspect(match))
      print(vim.inspect(remainder))
      print(vim.inspect(captures))
      if match ~= nil then
        return match, remainder, captures
      end
    end
  end
end

primitives.all = function(parsers)
  return function(input)
    local match, new_match, new_remainder, captures, sub_captures
    local remainder = input
    for _, parser in ipairs(parsers) do
      new_match, new_remainder, sub_captures = parse_and_capture(parser, remainder, captures)
      if new_match == nil then
        return nil
      end
      match = (match or "") .. new_match
      remainder = new_remainder
      if sub_captures ~= nil then
        captures = sub_captures
      end
    end
    print("IN ALL")
    print(vim.inspect(captures))
    return match, remainder, captures
  end
end

-- TODO: replace vim.join with table.concat everywhere
primitives.at_least = function(amount, parser)
  return function(input)
    local should_capture, match, remainder, sub_captures = parse(parser, input)
    local new_remainder
    local captures
    if should_capture then
      captures = {
        [parser.capture_identifier] = { sub_captures }
      }
    end

    local matches = { match }
    local total_matches = #matches
    while match ~= nil and remainder ~= "" do
      _, match, new_remainder, sub_captures = parse(parser, remainder)
      if match ~= nil then
        remainder = new_remainder
        total_matches = total_matches + 1
        matches[total_matches] = match
        if should_capture then
          if captures == nil then
            captures = {
              [parser.capture_identifier] = { sub_captures }
            }
          else
            local len = #captures[parser.capture_identifier]
            captures[parser.capture_identifier][len + 1] = sub_captures
          end
        end
      end
    end

    if amount == 0 and total_matches == 0 then
      return "", input, captures
    end

    if total_matches >= amount then
      local joined_matches = table.concat(matches)
      return joined_matches, remainder, captures
    end
  end
end

return primitives
