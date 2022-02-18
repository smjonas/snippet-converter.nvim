describe("Scenario", function()
  setup(function()
    local controller = require("snippet_converter.ui.controller")
    controller.create_view = function()
      --no-op
    end
    controller.finalize = function()
      --no-op
    end
  end)

  it("UltiSnips to VSCode scenario", function()
    local snippet_converter = require("snippet_converter")
    local template = {
      sources = {
        ultisnips = {
          "tests/scenarios/input.snippets",
        },
      },
      output = {
        vscode = { "tests/scenarios/output.json" },
      },
    }
    snippet_converter.setup { templates = { template } }
    -- Mock vim.schedule
    vim.schedule = function(fn)
      fn()
    end
    local model = snippet_converter.convert_snippets()
  end)

  it("UltiSnips to UltiSnips scenario", function()
    local snippet_converter = require("snippet_converter")
    local template = {
      sources = {
        ultisnips = {
          "tests/scenarios/ultisnips.snippets",
        },
      },
      output = {
        ultisnips = { "tests/scenarios/output.snippets" },
      },
    }
    snippet_converter.setup { templates = { template } }
    -- Mock vim.schedule
    vim.schedule = function(fn)
      fn()
    end
    local model = snippet_converter.convert_snippets()
  end)
end)
