local snippet_converter = require("snippet_converter")
local Model = require("snippet_converter.ui.model")

local snippet_engines = require("snippet_converter.snippet_engines")
local NodeType = require("snippet_converter.core.node_type")

local create_test_snippet = function(trigger, description, body)
  return {
    body = body or {
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
    description = description or "if/else statement",
    line_nr = 68,
    path = "/some/path/lua.snippets",
    trigger = trigger,
  }
end

describe("Snippet converter", function()
  local match = require("luassert.match")

  local model
  setup(function()
    model = Model.new()
    snippet_engines["vscode"].converter = "tests.init.converter_mock"
  end)

  it("should correctly apply local + global snippet transforms", function()
    local snippets = {
      ultisnips = {
        lua = {
          create_test_snippet("A"),
          create_test_snippet("B"),
          create_test_snippet("C"),
          create_test_snippet("D"),
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
      transform_snippets = function(snippet, helper)
        assert.are_same("ultisnips", helper.source_format)
        if snippet.trigger == "B" then
          snippet.description = "Updated description"
        elseif snippet.trigger == "C" then
          snippet.description = "Updated by local transform"
        else
          return nil
        end
        return snippet
      end,
    }
    snippet_converter.setup {
      templates = { template },
      transform_snippets = function(snippet, _)
        if snippet.trigger == "C" then
          snippet.description = "Updated by global transform"
        end
        return snippet
      end,
    }
    -- Submit task to ensure that the model is correctly initialized
    model:submit_task(template, "ultisnips", 1, 1, {})
    local stubbed_converter = stub.new(require("tests.init.converter_mock"), "export")

    local context = {}
    snippet_converter._convert_snippets(model, snippets, context, template)

    assert.stub(stubbed_converter).was.called_with(
      match.is_same {
        -- Can delete first and last snippet
        -- Can modify snippet by local transform
        'snippet B "Updated description"\nif $1 then\n\t$2\nelse\n\t$0\nend\nendsnippet',
        -- Can modify snippet by global transform (global should override local)
        'snippet C "Updated by global transform"\nif $1 then\n\t$2\nelse\n\t$0\nend\nendsnippet',
      },
      match.is_same("lua"),
      match.is_same("/some/path/lua.json"),
      match.is_same {}
    )
  end)

  it("should correctly apply global sorting and compare functions", function()
    local snippets = {
      ultisnips = {
        lua = {
          create_test_snippet("A", "I am second", {}),
          create_test_snippet("B", "ay, I should be last", {}),
          create_test_snippet("C", "The first (because T > a)", {}),
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
    }
    snippet_converter.setup {
      templates = { template },
      -- Sort by description in descending order
      sort_snippets = function(first, second)
        return first.description:lower() > second.description:lower()
      end,
    }
    -- Submit task to ensure that the model is correctly initialized
    model:submit_task(template, "ultisnips", 1, 1, {})
    local stubbed_converter = stub.new(require("tests.init.converter_mock"), "export")

    local context = {}
    snippet_converter._convert_snippets(model, snippets, context, template)

    assert.stub(stubbed_converter).was.called_with(
      match.is_same {
        'snippet C "The first (because T > a)"\n\nendsnippet',
        'snippet A "I am second"\n\nendsnippet',
        'snippet B "ay, I should be last"\n\nendsnippet',
      },
      match.is_same("lua"),
      match.is_same("/some/path/lua.json"),
      match.is_same {}
    )
  end)

  it("should correctly apply template sorting and compare functions overriding global functions", function()
    local snippets = {
      ultisnips = {
        lua = {
          create_test_snippet("A", "b second", {}),
          create_test_snippet("B", "c last", {}),
          create_test_snippet("C", "a first", {}),
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
      -- Sort by description in ascending order in the template...
      sort_snippets = function(first, second)
        return first.description < second.description
      end,
    }
    snippet_converter.setup {
      templates = { template },
      -- ...overriding the behavior of the global compare function
      sort_snippets = function(first, second)
        return first.trigger > second.trigger
      end,
    }
    -- Submit task to ensure that the model is correctly initialized
    model:submit_task(template, "ultisnips", 1, 1, {})
    local stubbed_converter = stub.new(require("tests.init.converter_mock"), "export")

    local context = {}
    snippet_converter._convert_snippets(model, snippets, context, template)

    assert.stub(stubbed_converter).was.called_with(
      match.is_same {
        'snippet C "a first"\n\nendsnippet',
        'snippet A "b second"\n\nendsnippet',
        'snippet B "c last"\n\nendsnippet',
      },
      match.is_same("lua"),
      match.is_same("/some/path/lua.json"),
      match.is_same {}
    )
  end)
end)
