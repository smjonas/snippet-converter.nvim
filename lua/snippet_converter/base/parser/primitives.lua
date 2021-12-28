local primitives = {}

primitives.pattern = function(_pattern)
  return function(input)
    local result = input:match("^" .. _pattern)
    if result ~= nil then
      return (result, input:sub(result:len())
    end
  end
end

primitives.either = function(parsers)
  return
  function(input)
    local result, new_remainder
    for _, parser in ipairs(parsers) do
      result, new_remainder = parser(input)
      if result ~= nil then
        return (result, new_remainder)
      end
    end
  end
end

primitives.all = function(parsers)
  return function(input)
    local result, new_result, new_remainder
    local remainder = input
    for _, parser in ipairs(parsers) do
      new_result, new_remainder = parser(remainder)
      if new_result ~= nil then
        result = (result or "") .. new_result
        remainder = new_remainder
      else
        return nil
      end
    end
    return (result, remainder)
  end
end

primitives.at_least = function(amount, parser)
  return function(input)
    local total_matches = 0
    local new_result
    local result, remainder = parser.parse(input)
    while result ~= nil do
      total_matches = total_matches + 1
      new_result, remainder = parser.parse(remainder)
      result = result .. new_result
    end
    if total_matches >= amount then
      return result, remainder
    end
  end
end

return primitives
