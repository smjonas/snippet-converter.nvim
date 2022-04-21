std = luajit
codes = true
max_line_length = 110
max_comment_line_length = false

self = false

read_globals = {
  "vim"
}

globals = {
  vim = {
    fields = {
      g
    }
  }
}
