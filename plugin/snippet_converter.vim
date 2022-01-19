if exists("g:loaded_snippet_converter")
  finish
endif
let g:loaded_snippet_converter = 1

command! -nargs=0 ConvertSnippets lua require("snippet_converter").convert_snippets()
