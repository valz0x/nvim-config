return {
	"numToStr/Comment.nvim",
	dependencies = {
		"JoosepAlviste/nvim-ts-context-commentstring",
	},
	config = function()
		local ok_ts, ts_comment = pcall(require, "ts_context_commentstring")
		if ok_ts then
			ts_comment.setup({
				enable_autocmd = false,
			})
		end

		local ok_ft, ft = pcall(require, "Comment.ft")
		if ok_ft then
			local orig_calculate = ft.calculate
			ft.calculate = function(ctx)
				local ok, parser = pcall(vim.treesitter.get_parser, vim.api.nvim_get_current_buf())
				if not ok or not parser then
					return ft.get(vim.bo.filetype, ctx.ctype) or vim.bo.commentstring
				end
				local ok_calc, res = pcall(orig_calculate, ctx)
				if ok_calc and res then
					return res
				end
				return ft.get(vim.bo.filetype, ctx.ctype) or vim.bo.commentstring
			end
		end

		local pre_hook
		local ok_integ, integ = pcall(require, "ts_context_commentstring.integrations.comment_nvim")
		if ok_integ then
			pre_hook = integ.create_pre_hook()
		end

		require("Comment").setup({
			padding = true,
			sticky = true,
			ignore = nil,
			toggler = {
				line = "gcc",
				block = "gbc",
			},
			opleader = {
				line = "gc",
				block = "gb",
			},
			extra = {
				above = "gcO",
				below = "gco",
				eol = "gcA",
			},
			mappings = {
				basic = true,
				extra = true,
			},
			pre_hook = pre_hook,
		})

		local map = vim.keymap.set
		map("n", "<C-/>", function()
			require("Comment.api").toggle.linewise.current()
		end, { desc = "Toggle comment" })
		map("n", "<C-_>", function()
			require("Comment.api").toggle.linewise.current()
		end, { desc = "Toggle comment (terminal)" })
		map("n", "<leader>/", function()
			require("Comment.api").toggle.linewise.current()
		end, { desc = "Toggle comment" })

		map("x", "<C-/>", '<Esc><Cmd>lua require("Comment.api").locked("toggle.linewise")(vim.fn.visualmode())<CR>', { desc = "Toggle comment" })
		map("x", "<C-_>", '<Esc><Cmd>lua require("Comment.api").locked("toggle.linewise")(vim.fn.visualmode())<CR>', { desc = "Toggle comment (terminal)" })
		map("x", "<leader>/", '<Esc><Cmd>lua require("Comment.api").locked("toggle.linewise")(vim.fn.visualmode())<CR>', { desc = "Toggle comment" })
	end,
}
