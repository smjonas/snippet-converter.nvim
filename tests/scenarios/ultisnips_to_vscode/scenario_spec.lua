describe("UltiSnips to VSCode scenario", function()
  local snippet_converter = require("snippet_converter")
  local template = {
    sources = {
      ultisnips = {
        "tests/scenarios/ultisnips_to_vscode/input.snippets",
      },
    },
    output = {
      vscode = { "tests/scenarios/ultisnips_to_vscode/output.json" },
    }
  }
  snippet_converter.setup { templates = { template }}
  -- Mock vim.schedule
  vim.schedule = function(fn) fn() end
  local model = snippet_converter.convert_snippets()
end)
