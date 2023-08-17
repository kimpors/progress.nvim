local M = {
	path = vim.api.nvim_command_output("echo stdpath('cache')") .. "/progress.nvim/",
}

function M.Save(sessions)
	vim.cmd("!mkdir -p " .. M.path)

	local file = io.open(M.path .. "cache", "w")

	for i = 1, #sessions, 1 do
		file:write("{ ")
		for key, value in pairs(sessions[i]) do
			if type(value) == "string" then
				value = "'" .. value .. "'"
			end

			file:write(key .. "=" .. value .. ", ")
		end
		file:write("}\n")
	end

	file:close()
end

function M.Load()
	local file = io.open(M.path .. "cache", "r")

	local result = {}
	local line = ""

	while true do
		line = file:read()

		if line == nil then
			break
		end

		local temp = load("return " .. line)()

		table.insert(result, temp)
	end

	file:close()

	return result
end

return M
