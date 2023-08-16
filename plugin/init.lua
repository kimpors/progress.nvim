local progress = require("progress")
local file = require("util.file")

progress.sessions = file.Load()

vim.api.nvim_create_user_command("Progress", "lua require('progress').Run()", {})
