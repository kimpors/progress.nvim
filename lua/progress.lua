local api = vim.api
local uv = vim.loop
local buf = 0

local M = {
	timer = uv.new_timer(),
	sessions = {},
}

function M.StartSession(session, timeout)
	M.timer:start(
		0,
		1000,
		vim.schedule_wrap(function()
			if session.time >= timeout then
				M.timer:stop()
				M.timer:close()

				M.Run()
			end

			session.time = session.time + 1000
		end)
	)

	return M.timer
end

function M.StopSession()
	M.timer:stop()
	M.timer:close()
end

function M.AddSession(name)
	table.insert(M.sessions, { name = name, time = 0 })
end

function M.Print()
	for _, value in ipairs(M.sessions) do
		print("name " .. value.name .. "\t" .. "time " .. value.time)
	end
end

function M.Display()
	buf = api.nvim_create_buf(false, true)

	local opts = {
		relative = "editor",
		width = 50,
		height = 20,
		row = 10,
		col = 10,
		style = "minimal",
		border = "rounded",
		title = "Progress",
		title_pos = "center",
	}

	api.nvim_open_win(buf, true, opts)
end

function M.SetContent()
	api.nvim_buf_set_option(buf, "modifiable", true)

	local sessions = {}

	for _, value in ipairs(M.sessions) do
		table.insert(sessions, value.name .. "\t|\t" .. value.time)
	end

	api.nvim_buf_set_lines(buf, -2, -1, false, sessions)
	api.nvim_buf_set_option(buf, "modifiable", false)
end

function M.Run()
	M.Display()
	M.SetContent()
end

return M
