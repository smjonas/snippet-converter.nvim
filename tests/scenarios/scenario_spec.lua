describe("Scenario", function()
  local expected_output_ultisnips, expected_output_vscode
  setup(function()
    local controller = require("snippet_converter.ui.controller")
    controller.create_view = function()
      --no-op
    end
    controller.finalize = function()
      --no-op
    end
    expected_output_ultisnips = vim.fn.readfile("tests/scenarios/expected_output_ultisnips.snippets")
    expected_output_vscode = vim.fn.readfile("tests/scenarios/expected_output_vscode.json")
  end)

  it("UltiSnips to VSCode", function()
    local snippet_converter = require("snippet_converter")
    local template = {
      sources = {
        ultisnips = {
          "tests/scenarios/ultisnips.snippets",
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
    local actual_output = vim.fn.readfile("tests/scenarios/output.json")
    snippet_converter.convert_snippets()
    assert.are_same(expected_output_vscode, actual_output)
  end)

  it("UltiSnips to UltiSnips", function()
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
    local actual_output = vim.fn.readfile("tests/scenarios/output.snippets")
    snippet_converter.convert_snippets()
    assert.are_same(expected_output_ultisnips, actual_output)
  end)
end)
