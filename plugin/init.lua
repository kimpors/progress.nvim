local progress = require("progress")

progress.AddSession("nvim")
progress.AddSession("lua")
progress.StartSession(progress.sessions[1], 2000)
