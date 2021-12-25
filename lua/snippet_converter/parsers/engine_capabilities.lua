-- Contains a list of features that a snippet-engine may support.
-- If the target engine also supports that capability, the snippet
-- can be converted.

local capabilities = {
  VIMSCRIPT_INTERPOLATION = 1,
}

capabilities.for_engine = {
  snipmate = {},
  ultisnips = {
    capabilities.VIMSCRIPT_INTERPOLATION
  },
  vscode = {},
}

return capabilities
