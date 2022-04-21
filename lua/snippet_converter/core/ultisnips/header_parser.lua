local M = {}

local function remove_surrounding_chars(string, tbl, tbl_index)
  local valid = string:sub(1, 1) == string:sub(-1, -1)
  if valid then
    -- This modifies the original captures table!
    tbl[tbl_index] = string:sub(2, -2)
  end
  return valid
end

M.handle_terminal_symbol = function(symbol, input)
  local start_idx, end_idx, capture = input:find(symbol)
  if start_idx ~= nil then
    local match = capture or input:sub(start_idx, end_idx)
    local remaining = input:sub(end_idx + 1)
    return { matches = { match }, remaining = remaining }
  end
  return nil
end

M.handle_non_terminal_symbol = function(production_name, grammar, input, force_parse_to_end)
  local production = grammar.productions[production_name]
  for _, rule in ipairs(production.rhs) do
    local matches = {}
    local cur_input = input

    local symbols = vim.split(rule, "%s")
    if vim.tbl_isempty(symbols) then
      symbols = { rule }
    end

    for _, symbol in ipairs(symbols) do
      local is_terminal_symbol = (grammar.productions[symbol] == nil)

      local result
      if is_terminal_symbol then
        result = M.handle_terminal_symbol(symbol, cur_input)
      else
        result = M.handle_non_terminal_symbol(symbol, grammar, cur_input)
      end

      if result ~= nil then
        -- Flatten table returned by handler
        if #result.matches == 1 then
          result.matches = result.matches[1]
        end
        table.insert(matches, result.matches)
        cur_input = result.remaining
      end
      -- The rule was successfully applied to the input string
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

M._parse = function(input, grammar, force_parse_to_end)
  return M.handle_non_terminal_symbol(grammar.start_symbol, grammar, input, force_parse_to_end)
end

M.parse = function(input)
  local result = {}
  local productions = {
    S = {
      rhs = {
        -- The first alternative must come before the second one here because
        -- we don't want to match the header 'Xtrigger "" biX' as a trigger.
        "options w description w trigger",
        "trigger",
        "description w trigger",
        "options w expression w description w trigger",
      },
      verify_matches = function(rule, matches)
        local trigger = matches[#matches]
        if rule == "options w expression w description w trigger" and trigger:match("e") == nil then
          return false
        end
        local has_r_options = rule:match("options") ~= nil and matches[1]:match("r") ~= nil
        if has_r_options or trigger:match("%s") then
          return remove_surrounding_chars(trigger, matches, #matches)
        end
        return true
      end,
      on_store_matches = function(symbols, matches)
        for i, match in ipairs(matches) do
          if symbols[i] ~= "w" then
            result[symbols[i]] = match:reverse()
          end
        end
      end,
    },
    trigger = {
      rhs = { [[^.+%S*]] },
    },
    description = {
      rhs = { [[^"([^"]*)"]] },
    },
    options = {
      rhs = { [[^[^"%s]+]] },
    },
    expression = {
      rhs = { [[^"(.-)"]] },
    },
    w = {
      rhs = { [[^%s+]] },
    },
  }
  local grammar = { start_symbol = "S", productions = productions }
  -- Reverse the string since we need to parse from right to left
  M._parse(input:reverse(), grammar, true)
  if not next(result) then
    error("invalid snippet header", 0)
  end
  return result
end

return M
