describe("Scenario", function()
  local expected_output_ultisnips, expected_output_snipmate, expected_output_vscode, expected_output_vscode_sorted
  setup(function()
    -- Mock vim.schedule
    vim.schedule = function(fn)
      fn()
    end

    local controller = require("snippet_converter.ui.controller")
    controller.create_view = function()
      --no-op
    end
    controller.finalize = function()
      --no-op
    end

    expected_output_ultisnips = vim.fn.readfile("tests/scenarios/expected_output_ultisnips.snippets")
    expected_output_snipmate = vim.fn.readfile("tests/scenarios/expected_output_snipmate.snippets")
    expected_output_vscode = vim.fn.readfile("tests/scenarios/expected_output_vscode.json")
    expected_output_vscode_sorted = vim.fn.readfile("tests/scenarios/expected_output_vscode_sorted.json")
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
        ultisnips = { "tests/scenarios/output_ultisnips.snippets" },
      },
    }
    snippet_converter.setup { templates = { template } }
    snippet_converter.convert_snippets()
    local actual_output = vim.fn.readfile("tests/scenarios/output_ultisnips.snippets")
    assert.are_same(expected_output_ultisnips, actual_output)
  end)

  it("UltiSnips to SnipMate", function()
    local snippet_converter = require("snippet_converter")
    local template = {
      sources = {
        ultisnips = {
          "tests/scenarios/ultisnips.snippets",
        },
      },
      output = {
        snipmate = { "tests/scenarios/output_snipmate.snippets" },
      },
    }
    snippet_converter.setup { templates = { template } }
    snippet_converter.convert_snippets()
    local actual_output = vim.fn.readfile("tests/scenarios/output_snipmate.snippets")
    assert.are_same(expected_output_snipmate, actual_output)
  end)

  it("UltiSnips to VSCode", function()
    -- TODO: continue with set snippet not correctly escaped (\\{$1\\\\} $0)
    local snippet_converter = require("snippet_converter")
    local template = {
      sources = {
        ultisnips = {
          "tests/scenarios/ultisnips.snippets",
        },
      },
      output = {
        -- Path can be either for a file or a containing folder
        vscode = { "tests/scenarios/output_vscode.json" },
      },
    }
    snippet_converter.setup { templates = { template } }
    snippet_converter.convert_snippets()
    local actual_output = vim.fn.readfile("tests/scenarios/output_vscode.json")
    assert.are_same(expected_output_vscode, actual_output)
  end)

  it("VSCode to VSCode", function()
    local snippet_converter = require("snippet_converter")
    local template = {
      sources = {
        vscode = {
          "tests/scenarios/expected_output_vscode.json",
        },
      },
      output = {
        vscode = { "tests/scenarios/output_vscode.json" },
      },
    }
    snippet_converter.setup {
      templates = { template },
      -- In the test, we care about their relative order if two items are the same in lower case
      compare = function(first, second)
        return first < second
      end,
    }

    snippet_converter.convert_snippets()
    local actual_output = vim.fn.readfile("tests/scenarios/output_vscode.json")
    assert.are_same(expected_output_vscode_sorted, actual_output)
  end)
end)
