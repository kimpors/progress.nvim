local time_format = require("util.time_format")

local api = vim.api
local uv = vim.loop
local win, buf = 0, 0

local cursor = { from = 0, current = 0, to = -1 }

local M = {
	timer = uv.new_timer(),
	sessions = {},
}

function M.StartSession(name, timeout)
	local session = false

	for _, value in ipairs(M.sessions) do
		if value.name == name then
			session = value
		end
	end

	if not session then
		print("ERROR. Session name doesn't exists")
		return 1
	end

	M.timer:start(
		1000,
		0,
		vim.schedule_wrap(function()
			session.time = session.time + 1000

			if session.time >= timeout then
				M.timer:stop()
				print("Done")
			end
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

	win = api.nvim_open_win(buf, true, opts)
end

function M.SetContent()
	api.nvim_buf_set_option(buf, "modifiable", true)

	local menu = {}

	table.insert(menu, "Your sessions:")

	cursor.from = 2
	cursor.current = 2

	for index, value in ipairs(M.sessions) do
		table.insert(menu, index .. ". " .. value.name .. "\t|\t\t" .. time_format.ToSeconds(value.time))
		cursor.to = index + 1
	end

	api.nvim_buf_set_lines(buf, -2, -1, false, menu)
	api.nvim_buf_set_option(buf, "modifiable", false)
end

function M.SetKeymaps(keymaps)
	local except = ""

	for key, _ in pairs(keymaps) do
		except = except .. key
	end

	local chars = {}
	for i = ("a"):byte(), ("z"):byte(), 1 do
		if not string.find(string.char(i), "[" .. except .. "]") then
			table.insert(chars, string.char(i))
		end
	end

	local opts = {
		nowait = true,
		noremap = true,
		silent = true,
	}

	for key, value in pairs(keymaps) do
		api.nvim_buf_set_keymap(buf, "n", key, ":lua require'" .. "progress" .. "'." .. value .. "<CR>", opts)
	end

	for _, value in pairs(chars) do
		api.nvim_buf_set_keymap(buf, "n", value, "", opts)
		api.nvim_buf_set_keymap(buf, "n", value:upper(), "", opts)
		api.nvim_buf_set_keymap(buf, "n", "<C-" .. value .. ">", "", opts)
	end
end

function M.Run()
	local keymaps = {
		j = "Move(1)",
		k = "Move(-1)",
		o = "Start()",
		q = "Exit()",
	}

	M.Display()
	M.SetContent()
	M.SetKeymaps(keymaps)
	M.Move(0)
end

function M.Move(vertical)
	cursor.current = cursor.current + vertical

	if cursor.current >= cursor.to then
		cursor.current = cursor.to
	elseif cursor.current <= cursor.from then
		cursor.current = cursor.from
	end

	api.nvim_win_set_cursor(win, { cursor.current, 0 })
end

function M.Start()
	local a = api.nvim_get_current_line()

	for _, value in ipairs(M.sessions) do
		if string.find(a, value.name) then
			a = value.name
		end
	end

	M.StartSession(a, 1000)
	M.Exit()
end

function M.Exit()
	api.nvim_win_close(win, false)
end

return M
