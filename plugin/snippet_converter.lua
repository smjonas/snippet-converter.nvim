local snippet_converter = require("snippet_converter")

-- TODO: change required Neovim version to 0.7 (incl. vim.json)
vim.api.nvim_add_user_command("ConvertSnippets", function(result)
  snippet_converter.convert_snippets(result.fargs)
end, { nargs = "*" })
