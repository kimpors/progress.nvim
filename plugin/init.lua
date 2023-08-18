require("util.globals")

local progress = require("progress")
local sessions = require("util.sessions")

API.nvim_create_user_command("Progress", "lua require('progress').Run()", {})

sessions.load()
progress.setup({ interval = 10 })
