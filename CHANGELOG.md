# Changelog

## [1.5.0](https://github.com/smjonas/snippet-converter.nvim/compare/v1.4.2...v1.5.0) (2023-02-11)


### Features

* add argument completion for :ConvertSnippets command ([2ba844f](https://github.com/smjonas/snippet-converter.nvim/commit/2ba844f06403f4fa0cac331b38b7b84fff506cc7))
* add keybinding to send parsing + conversion errors to the quickfix list ([078ab15](https://github.com/smjonas/snippet-converter.nvim/commit/078ab15c0d1e38693911575ef97fed756013836a))
* add mapping to send all input files to the quickfix list ([612fbdc](https://github.com/smjonas/snippet-converter.nvim/commit/612fbdc12cb423807ab1d0313611058a6f9b6ee5))
* add option to disable generating package.json file ([9d34713](https://github.com/smjonas/snippet-converter.nvim/commit/9d347132f89a2b39c5b5238c67d97060b5d5fcf0))
* add separate format for LuaSnip VSCode snippets (e.g. autotrigger is now respected); refactor parse methods ([d54f1aa](https://github.com/smjonas/snippet-converter.nvim/commit/d54f1aa68c171cd0abf979e1e95ab036cc026fb5))
* add support for Emac's YASnippet ([bdee9d1](https://github.com/smjonas/snippet-converter.nvim/commit/bdee9d17f99a71df18b468bdcef0ca8a8e7172c2))
* default_opts to override command options ([95d2c46](https://github.com/smjonas/snippet-converter.nvim/commit/95d2c4614cc41830f675c8e56405a4284d7929c6))
* **snipmate_luasnip:** support Vimscript code ([#9](https://github.com/smjonas/snippet-converter.nvim/issues/9)) ([2f3a53c](https://github.com/smjonas/snippet-converter.nvim/commit/2f3a53c96b10a831162eacfbdb8e025fde5bb7c0))
* **snipmate:** add snipmate_luasnip flavor ([a09be99](https://github.com/smjonas/snippet-converter.nvim/commit/a09be99577aeb36396648d9cf3e5c39e1cd73073))
* **snipmate:** parse snippet priorities (this extended syntax is supported by LuaSnip) ([f20e843](https://github.com/smjonas/snippet-converter.nvim/commit/f20e843754c63fa187bed98be09dc455b9542ecd))
* **ui:** &lt;C-o&gt; to send output files to quickfix list ([d324617](https://github.com/smjonas/snippet-converter.nvim/commit/d324617108da1e101cea0a260371b68be0278ea7))
* **ultisnips:** detect and remove unnecessary regex option in snippets ([0f4c3b3](https://github.com/smjonas/snippet-converter.nvim/commit/0f4c3b319684e00cd34a544ec70ccfb336a26111))
* **vscode_luasnip/ultisnips:** convert snippet priorities ([f4b0679](https://github.com/smjonas/snippet-converter.nvim/commit/f4b067925edb725722a08b7a362097c5a2d395f5))
* **vscode_luasnip:** don't convert variables to Vimscript ([1abbc97](https://github.com/smjonas/snippet-converter.nvim/commit/1abbc979b164a21e58fdf092c6f2d396afa98a1a))
* **vscode:** support if / else texts in format node ([2922aab](https://github.com/smjonas/snippet-converter.nvim/commit/2922aabbf92596e78c2b2659292e288a35f0a520))


### Bug Fixes

* add nil check when checking type of luasnip key ([f9f84d2](https://github.com/smjonas/snippet-converter.nvim/commit/f9f84d2ff687e107d9a03c45220c917562ace425))
* compatibility with LuaJIT (and Lua 5.1) ([264fb7c](https://github.com/smjonas/snippet-converter.nvim/commit/264fb7cac3e36b50696c42f222fa1753ed710bcf))
* export snippets for current filetype only ([ec3c73d](https://github.com/smjonas/snippet-converter.nvim/commit/ec3c73d8ff635590c7ba9676d7508919f3e98dfa))
* **json_utils:** correctly sort table by keys ([4d23af7](https://github.com/smjonas/snippet-converter.nvim/commit/4d23af7f7b1ec41de3910ba46335b3e4d7ca2889))
* **snipmate:** add tests; fix(parser): parse escaped } correctly ([5b235b6](https://github.com/smjonas/snippet-converter.nvim/commit/5b235b68736930ea3752315e3f694a307d848f30))
* **snipmate:** replace newline characters with whitespace in snippet description ([ccff794](https://github.com/smjonas/snippet-converter.nvim/commit/ccff794e74f8f89a0173fb9a9af2c761704bdfd3))
* **ultisnips:** convert + error out on invalid choice nodes; only support directory as output path ([9349bfa](https://github.com/smjonas/snippet-converter.nvim/commit/9349bfae198cb447ea39f0ed719cdcaedc63f533))
* **ultisnips:** correctly parse snippets with empty body or single empty line ([193ee47](https://github.com/smjonas/snippet-converter.nvim/commit/193ee47446a434b1baa94db3c67c05cda6e39aa4))
* **ultisnips:** ensure description is present if snippet options are set ([c47dc28](https://github.com/smjonas/snippet-converter.nvim/commit/c47dc283e4fc49d7ab554b2a1a573b7d5dcc103d))
* **ultisnips:** parse literal "endsnippet" in snippet definition ([f4ed0e4](https://github.com/smjonas/snippet-converter.nvim/commit/f4ed0e4ca258b58b6c91ef84d71cd223335d2d2f))
* **vscode_luasnip:** parse input snippets correctly; unify luasnip.autotrigger and autotrigger fields ([c3b815a](https://github.com/smjonas/snippet-converter.nvim/commit/c3b815a599cac8ba3c20b783609915e1966cc0c1))
* **vscode:** add a name to snippets returned from transformation function ([48842b6](https://github.com/smjonas/snippet-converter.nvim/commit/48842b63d8f6286625a60e94d7af91d7fb353e4b))
* **vscode:** convert visual placeholder to TM_SELECTED_TEXT variable ([29e7457](https://github.com/smjonas/snippet-converter.nvim/commit/29e74571c39b161c83ee159bf1e3b2d3067cd7a7))
* **vscode:** correctly handle UltiSnips extends directives when generating package.json file ([28f7153](https://github.com/smjonas/snippet-converter.nvim/commit/28f7153f51d927327caaa1b10db0971987f0ed3d))
* **VSCode:** disallow parsing 0 tabstop in choice node, convert choice node ([4b07896](https://github.com/smjonas/snippet-converter.nvim/commit/4b0789614ccf55fbcfc79605bc750a238f3e944c))
* **vscode:** do not try to convert snippets in package.json ([785648b](https://github.com/smjonas/snippet-converter.nvim/commit/785648b4809f3df6a901534f4df59ffd87790422))
* **vscode:** exclude package snippets in package.json to avoid LuaSnip error ([aa48221](https://github.com/smjonas/snippet-converter.nvim/commit/aa482219ab217974c57c99a6a949978afaff7a55))
* **vsnip:** escape $ in text nodes during conversion ([de0bc85](https://github.com/smjonas/snippet-converter.nvim/commit/de0bc85c72840e46b263ba6d832a2bd7cb121704))
