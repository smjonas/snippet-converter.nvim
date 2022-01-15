local snippet_engines = {}

-- Contains a list of features that a snippet-engine may support.
-- If the target engine also supports that capability, the snippet
-- can be converted.
local capabilities = {
  VIMSCRIPT_INTERPOLATION = 1,
}

snippet_engines.capabilities = capabilities

snippet_engines.snipmate = {
  extension = "*.snippets",
  parser = "snippet_converter.snipmate.parser",
  capabilities = {
    capabilities.VIMSCRIPT_INTERPOLATION,
  },
}

snippet_engines.ultisnips = {
  extension = "*.snippets",
  parser = "snippet_converter.ultisnips.parser",
  converter = "snippet_converter.ultisnips.converter",
}

snippet_engines.vscode = {
  extension = "*.json",
  parser = "snippet_converter.vscode.parser",
  converter = "snippet_converter.vscode.converter",
}

return snippet_engines
