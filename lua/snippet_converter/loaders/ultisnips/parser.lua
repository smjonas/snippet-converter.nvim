local parser = {}

local function table_is_empty(table)
  return next(table) == nil
end

local function iterator_to_table(iterator)
  local result = {}
  for x in iterator do
    table.insert(result, x)
  end
  return result
end

local function remove_surrounding_chars(string, tbl, tbl_index)
  local valid = string:sub(1, 1) == string:sub(-1, -1)
  if valid then
    -- This modifies the original captures table!
    tbl[tbl_index] = string:sub(2, -2)
  end
  return valid
end

parser.handle_terminal_symbol = function(symbol, input)
  local start_idx, end_idx, capture = input:find(symbol)
  if start_idx ~= nil then
    local match = capture or input:sub(start_idx, end_idx)
    local remaining = input:sub(end_idx + 1)
    return { matches = { match }, remaining = remaining }
  end
  return nil
end

parser.handle_non_terminal_symbol = function(production_name, grammar, input, force_parse_to_end)
  local production = grammar.productions[production_name]
  for _, rule in ipairs(production.rhs) do
    local matches = {}
    local cur_input = input

    -- TODO: replace with vim.split
    local symbols = iterator_to_table(rule:gmatch("%S+"))
    -- TODO: replace with vim.tbl_isempty
    if table_is_empty(symbols) then
      symbols = { rule }
    end

    for _, symbol in ipairs(symbols) do
      local is_terminal_symbol = (grammar.productions[symbol] == nil)

      local result
      if is_terminal_symbol then
        result = parser.handle_terminal_symbol(symbol, cur_input)
      else
        result = parser.handle_non_terminal_symbol(symbol, grammar, cur_input)
      end

      if result ~= nil then
        -- Flatten table returned by handler.
        if #result.matches == 1 then
          result.matches = result.matches[1]
        end
        table.insert(matches, result.matches)
        cur_input = result.remaining
      end
      -- The rule was successfully applied to the input string.
      if #matches == #symbols then
        if production_name ~= grammar.start_symbol or (not force_parse_to_end or cur_input == "") then
        -- Warning: verify function may change the contents of result.matches!
        -- Always assume that the table contents have changed beyond this point (e.g. when
        -- logging the current value).
          if production.verify_matches == nil or production.verify_matches(rule, matches) == true then
            if production.on_store_matches ~= nil then
              production.on_store_matches(symbols, matches)
            end
            return { matches = matches, remaining = cur_input }
          end
        end
      end
    end
  end
  return nil
end

parser.parse = function(input, grammar, force_parse_to_end)
  return parser.handle_non_terminal_symbol(grammar.start_symbol, grammar, input, force_parse_to_end)
end

parser.parse_snippet_header = function(input)
  local result = {}
  local productions = {
    S = {
      rhs = {
                                             "tab_trigger",
                               "description w tab_trigger",
                     "options w description w tab_trigger",
        "options w expression w description w tab_trigger",
      },
      verify_matches = function(rule, matches)
        local tab_trigger = matches[#matches]
        if rule == "options w expression w description w tab_trigger" and tab_trigger:match("e") == nil then
          return false
        end
        local has_r_options = rule:match("options") ~= nil and matches[1]:match("r") ~= nil
        if has_r_options or tab_trigger:match("%s") then
          return remove_surrounding_chars(tab_trigger, matches, #matches)
        end
        return true
      end,
      on_store_matches = function(symbols, matches)
        for i, match in ipairs(matches) do
          if symbols[i] ~= "w" then
            result[symbols[i]] = match:reverse()
          end
        end
      end
    },
    tab_trigger = {
      rhs = { '^.+%S*' },
    },
    description = {
      rhs = { '^"([^"]*)"' }
    },
    options = {
      rhs = { '^[^"%s]+' }
    },
    expression = {
      rhs = { '^"(.-)"' }
    },
    w = {
      rhs = { '^%s+' }
    }
  }
  local grammar = { start_symbol = "S", productions = productions }
  -- reverse the string since we need to parse from right to left
  parser.parse(input:reverse(), grammar, true)
  return result
end

return parser
