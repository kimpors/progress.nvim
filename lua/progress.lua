local file = require("util.file")
local id = nil

local api = vim.api
local uv = vim.loop
local win, buf = 0, 0

local cursor = { from = 0, current = 0, to = -1 }

local M = {
	timer = uv.new_timer(),
	sessions = {},
	config = {
		interval = 60 * 60,
	},
}

function M.StartSession(name, timeout)
	local time = 0
	local session = nil

	for _, value in ipairs(M.sessions) do
		if value.name == name then
			session = value
		end
	end

	M.timer:start(
		1000,
		1000,
		vim.schedule_wrap(function()
			session.time = session.time + 1
			time = time + 1

			if time >= timeout then
				M.timer:stop()

				file.Save(M.sessions)
				print("Done")
			end
		end)
	)

	return M.timer
end

function M.AddSession(name)
	table.insert(M.sessions, { name = name, time = 0 })
	file.Save(M.sessions)
end

function M.ShowSessions()
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

	if cursor.to > 1 then
		api.nvim_buf_set_lines(buf, 1, cursor.to, false, {})
	end

	local menu = {}

	table.insert(menu, "[o]Start\t[a]Add\t[r]Remove")
	table.insert(menu, "")
	table.insert(menu, "Your sessions:")

	cursor.from = 4
	cursor.current = 2

	local opts = {
		year = 0,
		month = 0,
		day = 0,
		hour = 0,
		min = 0,
		sec = 0,
	}

	cursor.to = cursor.current

	for index, value in ipairs(M.sessions) do
		opts.sec = value.time
		local time = os.date("%Hh %Mm %Ss", os.time(opts))

		table.insert(menu, index .. ". " .. value.name .. "\t|\t\t" .. time)
		cursor.to = index + 3
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

	api.nvim_buf_set_keymap(buf, "i", "<Enter>", "", opts)
end

function M.Run()
	local keymaps = {
		j = "Move(1)",
		k = "Move(-1)",
		o = "Start()",
		a = "Add()",
		r = "Remove()",
		q = "Exit()",
	}

	M.Display()
	M.SetContent()
	M.SetKeymaps(keymaps)
	M.Move(0)
end

function M.Add()
	api.nvim_buf_set_option(buf, "modifiable", true)

	api.nvim_buf_set_lines(buf, cursor.to, cursor.to + 1, false, { "" })
	cursor.to = cursor.to + 1

	api.nvim_win_set_cursor(win, { cursor.to, 1 })

	vim.cmd("startinsert")

	id = api.nvim_create_autocmd("InsertLeave", {
		callback = function()
			api.nvim_del_autocmd(id)
			api.nvim_buf_set_option(buf, "modifiable", false)
			M.AddSession(string.sub(api.nvim_get_current_line(), 1))
			M.SetContent()
			M.Move(0)
		end,
	})
end

function M.Remove()
	local line = api.nvim_get_current_line()

	for index, value in ipairs(M.sessions) do
		if string.find(line, value.name) then
			table.remove(M.sessions, index)
		end
	end

	file.Save(M.sessions)

	M.SetContent()
	M.Move(0)
end

-- TODO
-- function M.Edit()
-- 	local line = api.nvim_get_current_line()
-- 	local range = { start = nil, finish = nil }
--
-- 	range.start, range.finish = string.find(line, "%b[]$")
--
-- 	print(range.start, range.finish)
-- 	print(string.sub(line, range.start, range.finish))
--
-- 	api.nvim_win_set_cursor(win, { cursor.current, range.finish })
--
-- 	vim.cmd("startinsert")
-- end

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

	M.StartSession(a, M.config.interval)
	M.Exit()
end

function M.Exit()
	api.nvim_win_close(win, false)
end

function M.setup(opts)
	M.config = {
		interval = opts.interval or 60 * 60,
	}
end

return M
