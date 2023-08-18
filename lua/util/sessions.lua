local timer = vim.loop.new_timer()
local path = vim.api.nvim_command_output("echo stdpath('cache')") .. "/progress.nvim/"

local M = {
	index = 1,
	length = 0,
	list = {},
}

function M.add(opts)
	M.length = M.length + 1

	if type(opts) == "table" then
		table.insert(M.list, opts)
		return
	end

	if type(opts) == "string" then
		table.insert(M.list, { name = opts, time = 0 })
	end
end

function M.remove(name)
	if name == nil then
		table.remove(M.list, M.index)
	else
		for index, value in ipairs(M.list) do
			if value.name == name then
				table.remove(M.list, index)
			end
		end
	end
end

function M.next()
	if M.index >= M.length then
		M.index = M.length

		return false
	else
		M.index = M.index + 1

		return true
	end
end

function M.previous()
	if M.index <= 1 then
		M.index = 1

		return false
	else
		M.index = M.index - 1

		return true
	end
end

function M.current()
	return M.list[M.index]
end

function M.first()
	return M.list[1]
end

function M.last()
	return M.list[M.length]
end

function M.start(timeout)
	local time = 0
	local session = M.current()

	timer:start(
		1000,
		1000,
		vim.schedule_wrap(function()
			session.time = session.time + 1
			time = time + 1

			if time >= timeout then
				timer:stop()
				M.save()
				print("Done")
			end
		end)
	)

	return timer
end

function M.show()
	for _, value in ipairs(M.sessions) do
		print("name " .. value.name .. "\t" .. "time " .. value.time)
	end
end

function M.save()
	vim.cmd("silent !mkdir -p " .. path)

	local file = io.open(path .. "cache", "w")

	for i = 1, #M.list, 1 do
		file:write("{ ")
		for key, value in pairs(M.list[i]) do
			if type(value) == "string" then
				value = "'" .. value .. "'"
			end

			file:write(key .. "=" .. value .. ",")
		end
		file:write("}\n")
	end

	file:close()
end

function M.load()
	local file = io.open(path .. "cache", "r")
	local line = ""

	while true do
		line = file:read()

		if line == nil then
			break
		end

		local temp = ""
		if #line > 0 then
			temp = load("return " .. line)()
		end

		M.add(temp)
	end

	file:close()
end

return M
