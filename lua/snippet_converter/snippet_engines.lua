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
}

return snippet_engines
