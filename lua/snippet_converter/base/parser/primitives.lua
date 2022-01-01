local primitives = {}

primitives.pattern = function(_pattern)
  return function(input)
    local match = input:match("^" .. _pattern)
    if match ~= nil then
      return match, input:sub(match:len() + 1), nil
    end
  end
end

local get_capture_id = function(parser)
  if type(parser) == "table" then
    return parser.capture_identifier
  end
end

local parse_and_capture = function(parser, input, captures)
  local capture_id = get_capture_id(parser)
  if capture_id ~= nil then
    local match, remainder, sub_captures = parser.parser_fn(input)
    if match == nil then
      return nil
    end
    if captures == nil then
      captures = {
        [capture_id] = sub_captures or match
      }
    else
      -- The captures table already has an entry for that capture_id,
      -- so we create a list of subcaptures by merging the old and new values
      local existing_captures = captures[capture_id]
      if existing_captures == nil then
        captures[capture_id] = sub_captures or match
      else
        if type(existing_captures) == "table" then
          existing_captures[#existing_captures + 1] = sub_captures or match
        else
          -- A single value already exists
          captures[capture_id] = {
            existing_captures, sub_captures or match
          }
        end
      end
    end
    return match, remainder, captures
  else
    local match, remainder, sub_captures = parser(input)
    if sub_captures == nil then
      return match, remainder, captures
    end
    return match, remainder, sub_captures
  end
end

primitives.bind = function(capture_identifier, parser_fn)
  local parser = {
    capture_identifier = capture_identifier,
    parser_fn = parser_fn,
  }
  -- Allow calling parser table as a function
  setmetatable(parser, {
    __call = function(_, input)
      return parse_and_capture(parser, input, nil)
    end,
  })
  return parser
end

primitives.either = function(parsers)
  return function(input)
    local match, remainder, captures
    for _, parser in ipairs(parsers) do
      match, remainder, captures = parse_and_capture(parser, input, nil)
      if match ~= nil then
        return match, remainder, captures
      end
    end
  end
end

primitives.all = function(parsers)
  return function(input)
    local matches = {}
    local new_match, new_remainder, captures, sub_captures
    local remainder = input
    for _, parser in ipairs(parsers) do
      new_match, new_remainder, sub_captures = parse_and_capture(parser, remainder, captures)
      if new_match == nil then
        return nil
      end
      matches[#matches + 1] = new_match
      remainder = new_remainder
      if sub_captures ~= nil then
        captures = sub_captures
      end
    end
    return table.concat(matches), remainder, captures
  end
end

-- TODO: replace vim.join with table.concat everywhere
primitives.at_least = function(amount, parser)
  return function(input)
    local match, remainder, captures = parse_and_capture(parser, input, nil)
    local capture_id = get_capture_id(parser)
    if capture_id ~= nil then
      captures = { [capture_id] = { captures[capture_id] } }
    end
    local new_remainder
    local matches = { match }
    local new_captures

    while match ~= nil and remainder ~= "" do
      match, new_remainder, new_captures = parse_and_capture(parser, remainder, captures)
      if match ~= nil then
        matches[#matches + 1] = match
        remainder = new_remainder
        if new_captures ~= nil then
          captures = new_captures
        end
      end
    end

    local num_matches = #matches
    if amount == 0 and num_matches == 0 then
      return "", input, captures
    end

    if num_matches >= amount then
      return table.concat(matches), remainder, captures
    end
  end
end

return primitives
