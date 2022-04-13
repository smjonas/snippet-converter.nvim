local ultisnips_converter = require("snippet_converter.core.ultisnips.converter")
local converter = ultisnips_converter

converter.export = function(a, _, _, _)
  -- no-op
end

return converter
