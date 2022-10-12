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
    -- snippet_engines["vscode"].parser = "tests.init.parser_stub"
    snippet_engines["vscode"].converter = "tests.init.converter_stub"
  end)

  it("should correctly apply local + global snippet transforms", function()
    local snippets = {
      ultisnips = {
        lua = {
          create_test_snippet("A"),
          create_test_snippet("B"),
          create_test_snippet("C"),
          create_test_snippet("D"),
          create_test_snippet("E"),
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
        elseif snippet.trigger == "D" then
          return {
            ["if"] = {
              prefix = "if",
              body = { "if ${1:condition} then", "\t$0", "end" },
            },
          }, { format = "vscode" }
        else
          return false
        end
      end,
    }
    snippet_converter.setup {
      templates = { template },
      transform_snippets = function(snippet, _)
        if snippet.trigger == "C" then
          snippet.description = "Updated by global transform"
        end
      end,
    }
    -- Submit task to ensure that the model is correctly initialized
    model:submit_task(template, "ultisnips", 1, 1, {})
    local stubbed_converter = stub.new(require("tests.init.converter_stub"), "export")

    local context = {}
    snippet_converter._convert_snippets(model, snippets, context, template)

    assert.stub(stubbed_converter).was.called_with(
      match.is_same {
        -- Can delete first and last snippet
        -- Can modify snippet by local transform
        'snippet B "Updated description"\nif $1 then\n\t$2\nelse\n\t$0\nend\nendsnippet',
        -- Can modify snippet by global transform (global should override local)
        'snippet C "Updated by global transform"\nif $1 then\n\t$2\nelse\n\t$0\nend\nendsnippet',
        -- Can define snippet in different format
        "snippet if\nif ${1:condition} then\n\t$0\nend\nendsnippet",
      },
      match.is_same("lua"),
      match.is_same("/some/path/lua.json"),
      match.is_same {}
    )
  end)

  it("should support returning snippet string in transformation function", function()
    local snippets = {
      ultisnips = {
        lua = { create_test_snippet("A"), create_test_snippet("B") },
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
        assert.are_same(require("snippet_converter.core.ultisnips.parser"), helper.parser)
        if snippet.trigger == "A" then
          -- A should be kept because opts.replace was not specified => default is true
          return helper.dedent([[
            snippet new
            Please parse me :3
            endsnippet

            snippet new
            Invalid syntax error: ${0|choice|}
            endsnippet
          ]])
        elseif snippet.trigger == "B" then
          return helper.dedent([[
            snippet new
            Please parse me too :3
            endsnippet
          ]]),
            { replace = false }
        end
      end,
    }
    snippet_converter.setup {
      templates = { template },
    }
    -- Submit task to ensure that the model is correctly initialized
    model:submit_task(template, "ultisnips", 1, 1, {})
    local stubbed_converter = stub.new(require("tests.init.converter_stub"), "export")
    local stubbed_notify = stub.new(vim, "notify")

    local context = {}
    snippet_converter._convert_snippets(model, snippets, context, template)

    assert.stub(stubbed_converter).was.called_with(
      match.is_same {
        -- Snippet B should be kept
        'snippet B "if/else statement"\nif $1 then\n\t$2\nelse\n\t$0\nend\nendsnippet',
        -- Checks that the snippet strings were parsed and successfully converted
        "snippet new\nPlease parse me :3\nendsnippet",
        -- New snippets should be placed after the existing snippets
        "snippet new\nPlease parse me too :3\nendsnippet",
      },
      match.is_same("lua"),
      match.is_same("/some/path/lua.json"),
      match.is_same {}
    )

    assert.stub(stubbed_notify).was.called_with(
      match.is_same(
        "[snippet-converter.nvim] error while parsing snippet in transform function: choice node placeholder must not be 0 at 'choice|}' (input line: 'Invalid syntax error: ${0|choice|}')"
      ),
      match.is_same(vim.log.levels.ERROR)
    )
  end)

  it("should show error when no valid snippets were returned in transform function", function()
    local snippets = {
      ultisnips = {
        lua = { create_test_snippet("A") },
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
        return "this is not a valid snippet", { replace = false }
      end,
    }
    snippet_converter.setup {
      templates = { template },
    }
    -- Submit task to ensure that the model is correctly initialized
    model:submit_task(template, "ultisnips", 1, 1, {})
    local stubbed_converter = stub.new(require("tests.init.converter_stub"), "export")
    local stubbed_notify = stub.new(vim, "notify")

    local context = {}
    snippet_converter._convert_snippets(model, snippets, context, template)

    assert.stub(stubbed_converter).was.called_with(
      match.is_same {
        -- Original snippet should be unchanged
        'snippet A "if/else statement"\nif $1 then\n\t$2\nelse\n\t$0\nend\nendsnippet',
      },
      match.is_same("lua"),
      match.is_same("/some/path/lua.json"),
      match.is_same {}
    )

    assert.stub(stubbed_notify).was.called_with(
      match.is_same(
        "[snippet-converter.nvim] no valid snippets were found; please return a valid snippet string or table from the transform function"
      ),
      match.is_same(vim.log.levels.ERROR)
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
    local stubbed_converter = stub.new(require("tests.init.converter_stub"), "export")

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
    local stubbed_converter = stub.new(require("tests.init.converter_stub"), "export")

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

  describe("(VSCode)", function()
    it("should skip package.json input file", function()
      local package_snippet = create_test_snippet("B", "", {})
      package_snippet.path = "some/path/package.json"

      local snippets = {
        vscode = {
          lua = {
            create_test_snippet("A", "", {}),
          },
          package = {
            package_snippet,
          },
        },
      }

      local template = {
        sources = {
          vscode = {
            "/some/path",
          },
        },
        output = {
          ultisnips = { "/some/output_path" },
        },
      }
      snippet_converter.setup {
        templates = { template },
      }
      -- Submit task to ensure that the model is correctly initialized
      model:submit_task(template, "vscode", 1, 1, {})
      local stubbed_converter = stub.new(require("tests.init.converter_stub"), "export")

      local snippet_paths = {
        vscode = { package = { "some/path/package.json" }, lua = { "some/path/lua.json" } },
      }
      local stubbed_parser = stub.new(require("tests.init.parser_stub"), "export")

      -- What is returned by the mocked parser here is the list of file paths passed to it
      local snippets, context = snippet_converter._parse_snippets(model, snippet_paths, template)
      assert.are_same(snippets, {
        vscode = {
          lua = { "some/path/lua.json" },
          package = {},
        },
      })
      assert.are_same({ global_code = {}, langs_per_filetype = {} }, context)
    end)
  end)
end)
