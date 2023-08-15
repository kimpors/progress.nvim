local uv = vim.loop

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

				print("name " .. session.name .. "\t" .. "time " .. session.time)
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

return M
