local M = {
	buf = 0,
	win = 0,
}

function M.Render(opts)
	M.buf = API.nvim_create_buf(false, true)
	M.win = API.nvim_open_win(M.buf, true, opts.win)

	API.nvim_buf_set_option(M.buf, "modifiable", true)

	API.nvim_buf_set_lines(M.buf, -2, 1, false, { table.concat(opts.content.items, "\t") })

	API.nvim_buf_set_lines(M.buf, 2, -1, false, opts.content.body)
	API.nvim_buf_set_option(M.buf, "modifiable", false)

	return M.buf, M.win
end

function M.Menu(opts)
	return M.Render({
		win = {
			relative = "editor",
			width = 50,
			height = 20,
			row = 10,
			col = 10,
			style = "minimal",
			border = "rounded",
		},
		content = opts,
	})
end

return M
