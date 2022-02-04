describe("UltiSnips to VSCode scenario", function()
  local snippet_converter = require("snippet_converter")
  -- TODO: change to setup
  snippet_converter.set_pipeline {
    sources = {
      ultisnips = {
        "tests/scenarios/ultisnips_to_vscode/input.snippets",
      },
    },
    output = {
      -- TODO: handle case where output path is file (not directory)
      vscode = { "tests/scenarios/ultisnips_to_vscode/output.json" },
    },
  }
  local model = snippet_converter.convert_snippets()
  print(vim.inspect(model))
end)
