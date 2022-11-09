describe("Scenario", function()
  local expected_output_ultisnips, expected_output_ultisnips_from_vscode_luasnip, expected_output_snipmate, expected_output_yasnippet_main, expected_output_yasnippet_pairs, expected_output_vscode, expected_output_vscode_sorted, expected_output_vscode_luasnip
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
    expected_output_ultisnips_from_vscode_luasnip =
      vim.fn.readfile("tests/scenarios/expected_output_ultisnips_from_vscode_luasnip.snippets")
    expected_output_snipmate = vim.fn.readfile("tests/scenarios/expected_output_snipmate.snippets")
    expected_output_yasnippet_main = vim.fn.readfile("tests/scenarios/expected_output_yasnippet_main")
    expected_output_yasnippet_pairs = vim.fn.readfile("tests/scenarios/expected_output_yasnippet_pairs")
    expected_output_vscode = vim.fn.readfile("tests/scenarios/expected_output_vscode.json")
    expected_output_vscode_luasnip = vim.fn.readfile("tests/scenarios/expected_output_vscode_luasnip.json")
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
        ultisnips = { "tests/scenarios/output" },
      },
    }
    snippet_converter.setup { templates = { template } }
    snippet_converter.convert_snippets()
    local actual_output = vim.fn.readfile("tests/scenarios/output/ultisnips.snippets")
    assert.are_same(expected_output_ultisnips, actual_output)
  end)

  it("UltiSnips to VSCode", function()
    local snippet_converter = require("snippet_converter")
    local template = {
      sources = {
        ultisnips = {
          "./tests/scenarios/ultisnips.snippets",
        },
      },
      output = {
        -- Path can be either for a file or a containing folder
        vscode = { "tests/scenarios/output" },
      },
    }
    snippet_converter.setup { templates = { template } }
    snippet_converter.convert_snippets()
    local actual_output = vim.fn.readfile("tests/scenarios/output/ultisnips.json")
    assert.are_same(expected_output_vscode, actual_output)
  end)

  it("UltiSnips to VSCode_LuaSnip", function()
    local snippet_converter = require("snippet_converter")
    local template = {
      sources = {
        ultisnips = {
          "./tests/scenarios/ultisnips.snippets",
        },
      },
      output = {
        -- Path can be either for a file or a containing folder
        vscode_luasnip = { "tests/scenarios/output" },
      },
    }
    snippet_converter.setup { templates = { template } }
    snippet_converter.convert_snippets()
    local actual_output = vim.fn.readfile("tests/scenarios/output/ultisnips.json")
    assert.are_same(expected_output_vscode_luasnip, actual_output)
  end)

  it("VSCode_LuaSnip to UltiSnips", function()
    local snippet_converter = require("snippet_converter")
    local template = {
      sources = {
        vscode_luasnip = {
          "tests/scenarios/expected_output_vscode_luasnip.json",
        },
      },
      output = {
        ultisnips = { "tests/scenarios/output" },
      },
    }
    snippet_converter.setup {
      templates = { template },
    }

    snippet_converter.convert_snippets()
    local actual_output = vim.fn.readfile("tests/scenarios/output/expected_output_vscode_luasnip.snippets")
    assert.are_same(expected_output_ultisnips_from_vscode_luasnip, actual_output)
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
        snipmate = { "tests/scenarios/output" },
      },
    }
    snippet_converter.setup { templates = { template } }
    snippet_converter.convert_snippets()
    local actual_output = vim.fn.readfile("tests/scenarios/output/ultisnips.snippets")
    assert.are_same(expected_output_snipmate, actual_output)
  end)

  it("SnipMate to SnipMate", function()
    local snippet_converter = require("snippet_converter")
    local template = {
      sources = {
        snipmate = {
          "tests/scenarios/expected_output_snipmate.snippets",
        },
      },
      output = {
        snipmate = { "tests/scenarios/output" },
      },
    }
    snippet_converter.setup { templates = { template } }
    snippet_converter.convert_snippets()
    local actual_output = vim.fn.readfile("tests/scenarios/output/expected_output_snipmate.snippets")
    assert.are_same(expected_output_snipmate, actual_output)
  end)

  it("YASnippet to YASnippet", function()
    local snippet_converter = require("snippet_converter")
    local template = {
      sources = {
        yasnippet = {
          "tests/scenarios/yasnippet-mode",
        },
      },
      output = {
        yasnippet = { "tests/scenarios/output" },
      },
    }
    snippet_converter.setup { templates = { template } }
    snippet_converter.convert_snippets()
    local actual_output_main = vim.fn.readfile("tests/scenarios/output/yasnippet-mode/main")
    local actual_output_pairs = vim.fn.readfile("tests/scenarios/output/yasnippet-mode/pairs")
    assert.are_same(expected_output_yasnippet_main, actual_output_main)
    assert.are_same(expected_output_yasnippet_pairs, actual_output_pairs)
  end)

  it("VSCode to VSCode", function()
    local snippet_converter = require("snippet_converter")
    local template = {
      sources = {
        vscode = {
          "tests/scenarios/expected_output_vscode_sorted.json",
        },
      },
      output = {
        vscode = { "tests/scenarios/output" },
      },
    }
    snippet_converter.setup {
      templates = { template },
    }

    snippet_converter.convert_snippets()
    local actual_output = vim.fn.readfile("tests/scenarios/output/expected_output_vscode_sorted.json")
    assert.are_same(expected_output_vscode_sorted, actual_output)
  end)
end)
