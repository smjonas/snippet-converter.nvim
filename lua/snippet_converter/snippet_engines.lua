local snippet_engines = {}

-- When reading the JSON data into a table, the order is not guaranteed.
-- In order to avoid indeterminism, sort by the snippet name by default.
local json_sort_snippets = function(first, second)
  return first.name < second.name
end

snippet_engines.snipmate = {
  label = "SnipMate",
  extension = "snippets",
  global_filename = "_",
  parser = "snippet_converter.core.snipmate.parser",
  converter = "snippet_converter.core.snipmate.converter",
}

snippet_engines.ultisnips = {
  label = "UltiSnips",
  extension = "snippets",
  global_filename = "all",
  parser = "snippet_converter.core.ultisnips.parser",
  converter = "snippet_converter.core.ultisnips.converter",
}

snippet_engines.vscode = {
  label = "VSCode",
  base_format = "vscode",
  extension = "json",
  global_filename = "all",
  parser = "snippet_converter.core.vscode.parser",
  converter = "snippet_converter.core.vscode.converter",
  default_sort_snippets = json_sort_snippets,
}

snippet_engines.vscode_luasnip = {
  label = "VSCode (LuaSnip)",
  base_format = "vscode",
  extension = "json",
  global_filename = "all",
  parser = "snippet_converter.core.vscode.luasnip.parser",
  converter = "snippet_converter.core.vscode.luasnip.converter",
  default_sort_snippets = json_sort_snippets,
}

snippet_engines.vsnip = {
  label = "vsnip",
  base_format = "vscode",
  extension = "json",
  global_filename = "all",
  parser = "snippet_converter.core.vscode.vsnip.parser",
  converter = "snippet_converter.core.vscode.vsnip.converter",
  default_sort_snippets = json_sort_snippets,
}

return snippet_engines
