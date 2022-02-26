local snippet_converter = require("snippet_converter")
-- TODO: maybe move model to a different module?
local Model = require("snippet_converter.ui.model")

local snippet_engines = require("snippet_converter.snippet_engines")
local NodeType = require("snippet_converter.core.node_type")

local create_test_snippet = function(trigger_name)
  return {
    body = {
      {
        text = "if ",
        type = NodeType.TEXT,
      },
      {
        int = "1",
        type = NodeType.TABSTOP,
      },
      {
        text = " then\n\t",
        type = NodeType.TEXT,
      },
      {
        int = "2",
        type = NodeType.TABSTOP,
      },
      {
        text = "\nelse\n\t",
        type = NodeType.TEXT,
      },
      {
        int = "0",
        type = NodeType.TABSTOP,
      },
      {
        text = "\nend",
        type = NodeType.TEXT,
      },
    },
    description = "if/else statement",
    line_nr = 68,
    options = "b",
    path = "/some/path/lua.snippets",
    trigger = trigger_name,
  }
end

describe("Snippet converter", function()
  local match = require("luassert.match")

  local model
  setup(function()
    model = Model.new()
    snippet_engines["vscode"].converter = "tests.init.converter_mock"
    -- Submit task to ensure that the model is correctly initialized
    model:submit_task("ultisnips", 1, 1, {})
  end)

  it("should correctly apply snippet transform", function()
    local snippets = {
      ultisnips = {
        lua = {
          create_test_snippet("A"),
          create_test_snippet("B"),
          create_test_snippet("C"),
        },
      },
    }

    local template = {
      sources = {
        ultisnips = {
          "/some/path/lua.snippets",
        },
      },
      output = {
        vscode = { "/some/path/lua.json" },
      },
      transform_snippets = function(snippet, source_format)
        assert.are_same("ultisnips", source_format)
        if snippet.trigger == "A" then
          snippet.description = "Updated description"
          return snippet
        elseif snippet.trigger == "B" then
          return "snippet code to be exported"
        elseif snippet.trigger == "C" then
          return nil
        end
      end,
    }
    snippet_converter.setup { templates = { template } }
    local stubbed_converter = stub.new(require("tests.init.converter_mock"), "export")
    local context = {}
    snippet_converter._convert_snippets(model, snippets, context, template.output)

    assert.stub(stubbed_converter).was.called_with(
      match.is_same {
        -- Can modify snippet
        'snippet A "Updated description"\nif $1 then\n\t$2\nelse\n\t$0\nend\nendsnippet',
        -- Can set converted snippet text
        "snippet code to be exported",
        -- Can delete snippet
      },
      match.is_same("lua"),
      match.is_same("/some/path/lua.json"),
      match.is_same {}
    )
  end)
end)
