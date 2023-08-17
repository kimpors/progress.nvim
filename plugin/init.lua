local progress = require("progress")
local file = require("util.file")

progress.sessions = file.Load()

vim.api.nvim_create_user_command("Progress", "lua require('progress').Run()", {})

progress.setup({ interval = 10 })

local relative_filepath = vim.fn.expand("%:t")
print(relative_filepath)
print(relative_filepath)
