local M = {}

function M.ToMiliSeconds(ms)
	return ms .. "ms"
end

function M.ToSeconds(ms)
	return ms / 1000 .. "s"
end

function M.ToMinutes(ms)
	local secs = ms / 1000
	local mins = secs / 60

	return mins .. "m"
end

return M
