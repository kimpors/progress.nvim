local progress = require("progress")

progress.AddSession("nvim")
progress.AddSession("lua")

vim.api.nvim_create_user_command("Progress", "lua require('progress').Run()", {})
