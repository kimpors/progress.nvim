local api = vim.api
local progress = require("progress")
local file = require("util.file")

progress.sessions = file.Load()

api.nvim_create_user_command("Progress", "lua require('progress').Run()", {})

progress.setup({ interval = 10 })
