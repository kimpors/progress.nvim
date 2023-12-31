local sessions = require("util.sessions")
local ui = require("util.ui")

local id = nil
local offset = 0
local win, buf = 0, 0

local M = {
	config = {
		interval = 60 * 60,
	},
}

function M.Menu()
	local menu = {
		items = {
			"[o]Start",
			"[a]Add",
			"[r]Remove",
			"[e]Edit",
		},
		body = {
			"",
			"Your sessions: ",
		},
	}

	offset = #menu.body + 1

	local opts = {
		year = 0,
		month = 0,
		day = 0,
		hour = 0,
		min = 0,
		sec = 0,
	}

	for index, value in ipairs(sessions.list) do
		opts.sec = value.time
		local time = os.date("%Hh %Mm %Ss", os.time(opts))
		table.insert(menu.body, index .. ". " .. value.name .. "\t|\t\t" .. time)
	end

	buf, win = ui.Menu(menu)
end

function M.Update()
	API.nvim_buf_set_option(buf, "modifiable", true)

	local menu = {}

	local opts = {
		year = 0,
		month = 0,
		day = 0,
		hour = 0,
		min = 0,
		sec = 0,
	}

	for index, value in ipairs(sessions.list) do
		opts.sec = value.time
		local time = os.date("%Hh %Mm %Ss", os.time(opts))
		table.insert(menu, index .. ". " .. value.name .. "\t|\t\t" .. time)
	end

	API.nvim_buf_set_lines(buf, offset, -1, false, menu)
	API.nvim_buf_set_option(buf, "modifiable", false)
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
		API.nvim_buf_set_keymap(buf, "n", key, ":lua require'" .. "progress" .. "'." .. value .. "<CR>", opts)
	end

	for _, value in pairs(chars) do
		API.nvim_buf_set_keymap(buf, "n", value, "", opts)
		API.nvim_buf_set_keymap(buf, "n", value:upper(), "", opts)
		API.nvim_buf_set_keymap(buf, "n", "<C-" .. value .. ">", "", opts)
	end

	API.nvim_buf_set_keymap(buf, "i", "<Enter>", "", opts)
end

function M.Add()
	API.nvim_buf_set_option(buf, "modifiable", true)

	local lastLine = sessions.length + offset

	API.nvim_buf_set_lines(buf, lastLine, lastLine + 1, false, { "" })
	API.nvim_win_set_cursor(win, { lastLine + 1, 1 })

	vim.cmd("startinsert")

	id = API.nvim_create_autocmd("InsertLeave", {
		callback = function()
			API.nvim_del_autocmd(id)
			API.nvim_buf_set_option(buf, "modifiable", false)

			local isExist = false
			local name = string.sub(API.nvim_get_current_line(), 1)

			for _, value in ipairs(sessions.list) do
				if name == value.name then
					isExist = true
				end
			end

			if not isExist then
				sessions.add(string.sub(API.nvim_get_current_line(), 1))
				sessions.save()
			else
				print("'" .. name .. "'" .. " already exist")
			end

			M.Update()
			M.Move(0)
		end,
	})
end

function M.Remove()
	sessions.remove()
	sessions.save()

	M.Update()
	M.Move(0)
end

function M.Edit()
	API.nvim_buf_set_option(buf, "modifiable", true)

	API.nvim_set_current_line(sessions.current().name)
	API.nvim_win_set_cursor(win, { sessions.index + offset, #sessions.current().name })
	vim.cmd("startinsert")

	id = API.nvim_create_autocmd("InsertLeave", {
		callback = function()
			API.nvim_buf_set_option(buf, "modifiable", false)
			API.nvim_del_autocmd(id)
			API.nvim_buf_set_option(buf, "modifiable", false)

			local name = string.sub(API.nvim_get_current_line(), 1)

			sessions.current().name = name
			sessions.save()
			M.Update()
			M.Move(0)
		end,
	})
end

function M.Move(vertical)
	if vertical > 0 then
		sessions.next()
	else
		sessions.previous()
	end

	API.nvim_win_set_cursor(win, { sessions.index + offset, 0 })
end

function M.Start()
	sessions.start(M.config.interval)
	M.Exit()
end

function M.Exit()
	API.nvim_win_close(win, false)
end

function M.setup(opts)
	M.config = {
		interval = opts.interval,
	}
end

function M.Run()
	local keymaps = {
		j = "Move(1)",
		k = "Move(-1)",
		o = "Start()",
		a = "Add()",
		e = "Edit()",
		r = "Remove()",
		q = "Exit()",
	}

	M.Menu()
	M.SetKeymaps(keymaps)
	M.Move(0)
end

return M
