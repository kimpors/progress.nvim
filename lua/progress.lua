local M = {
	sessions = {},
}

function M.AddSession(name)
	table.insert(M.sessions, { name = name, time = 0 })
end

function M.Print()
	for _, value in ipairs(M.sessions) do
		print("name " .. value.name .. "\t" .. "time " .. value.time)
	end
end

return M
