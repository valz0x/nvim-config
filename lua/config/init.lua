--require('nvim-treesitter.install').compilers = { "gcc" }
-- require("config.nvchadUi")
require("config.set")
require("config.remap")

vim.opt.termguicolors = true
-- message be buffer
vim.o.cmdheight = 0
local ok_ui2, ui2 = pcall(require, "vim._core.ui2")
if ok_ui2 and ui2.enable then
	ui2.enable({
		enable = true,
		msg = {
			target = "cmd",
			pager = { height = 0.5 },
			dialog = { height = 0.5 },
			cmd = { height = 0.5 },
			msg = { height = 0.5, timeout = 4500 },
		},
	})
end
-- Rounded completion menu
vim.opt.pumborder = "rounded"

-- Rounded borders for built-in floating windows
vim.opt.winborder = "rounded"

-- No command line when idle (works especially well with UI2)
vim.opt.cmdheight = 0

vim.cmd("syntax on")
vim.cmd("filetype plugin indent on")

local augroup = vim.api.nvim_create_augroup
local group = augroup("thePayman", {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup("HighlightYank", {})

function R(name)
	require("plenary.reload").reload_module(name)
end

autocmd("TextYankPost", {
	group = yank_group,
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({
			higroup = "IncSearch",
			timeout = 40,
		})
	end,
})

autocmd({ "BufWritePre" }, {
	group = group,
	pattern = "*",
	command = [[%s/\s\+$//e]],
})

function ColorMyPencils(color, noBg)
	color = color or "kanagawa"
	noBg = noBg or false
	vim.cmd.colorscheme(color)
	if noBg then
		local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
		local normal_float = vim.api.nvim_get_hl(0, { name = "NormalFloat" })
		vim.api.nvim_set_hl(0, "Normal", vim.tbl_extend("force", normal, { bg = "none", ctermbg = "none" }))
		vim.api.nvim_set_hl(0, "NormalFloat", vim.tbl_extend("force", normal_float, { bg = "none", ctermbg = "none" }))
	end
end
function PickColorscheme()
	-- picker implementation
end
