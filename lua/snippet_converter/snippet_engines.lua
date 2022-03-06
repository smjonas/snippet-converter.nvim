local snippet_engines = {}

snippet_engines.snipmate = {
  label = "SnipMate",
  extension = "snippets",
  all_filename = "_",
  parser = "snippet_converter.core.snipmate.parser",
  converter = "snippet_converter.core.snipmate.converter",
}

snippet_engines.ultisnips = {
  label = "UltiSnips",
  extension = "snippets",
  all_filename = "all",
  parser = "snippet_converter.core.ultisnips.parser",
  converter = "snippet_converter.core.ultisnips.converter",
}

snippet_engines.vscode = {
  label = "VSCode",
  extension = "json",
  parser = "snippet_converter.core.vscode.parser",
  converter = "snippet_converter.core.vscode.converter",
  -- When reading the JSON data into a table, the order is not guaranteed.
  -- In order to avoid indeterminism, sort by the snippet name by default.
  default_sort_by = function(snippet)
    return snippet.name
  end,
  default_compare = function(first, second)
    return first:upper() < second:upper()
  end,
}

snippet_engines.vsnip = {
  label = "vsnip",
  extension = "json",
  parser = "snippet_converter.core.vscode.vsnip.parser",
  converter = "snippet_converter.core.vscode.vsnip.converter",
  -- When reading the JSON data into a table, the order is not guaranteed.
  -- In order to avoid indeterminism, sort by the snippet name by default.
  default_sort_by = function(snippet)
    return snippet.name
  end,
  default_compare = function(first, second)
    return first:upper() < second:upper()
  end,
}

return snippet_engines
