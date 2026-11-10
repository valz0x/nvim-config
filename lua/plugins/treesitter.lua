return {

	{
		-- The "main" branch is a full rewrite: it only installs/updates parsers now.
		-- Highlighting, folding, etc. are enabled ourselves below via core `vim.treesitter`.
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		build = ":TSUpdate",
		config = function()
			local ok, treesitter = pcall(require, "nvim-treesitter")
			if not ok then
				return
			end

			-- Ensure nvim-treesitter runtime queries are in runtimepath
			local ts_runtime = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt", "nvim-treesitter", "runtime")
			if vim.fn.isdirectory(ts_runtime) == 1 then
				vim.opt.rtp:append(ts_runtime)
			end

			-- Languages to install (excluding Neovim 0.12 bundled parsers: vim, vimdoc, c, lua, markdown, query)
			local target_langs = {
				"c_sharp", "rust", "cpp", "python", "go",
				"javascript", "typescript", "tsx", "html", "css", "svelte",
				"json", "yaml", "toml", "bash", "diff", "regex",
				"sql", "dockerfile", "gitignore", "git_config", "php",
			}

			local function install_missing()
				local needed = {}
				for _, lang in ipairs(target_langs) do
					if not vim.treesitter.language.add(lang) then
						table.insert(needed, lang)
					end
				end
				if #needed > 0 then
					treesitter.install(needed)
				end
			end

			vim.api.nvim_create_user_command("TSInstallMissing", install_missing, {
				desc = "Install missing Tree-sitter parsers",
			})

			-- Highlighting is provided by core Neovim; nvim-treesitter only manages parsers now.
			vim.api.nvim_create_autocmd("FileType", {
				callback = function(args)
					if pcall(vim.treesitter.start, args.buf) then
						vim.wo[0][0].foldmethod = "expr"
						vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
					end
				end,
			})
		end,
	},
	{
		"windwp/nvim-ts-autotag",
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},
	{ "nvim-treesitter/nvim-treesitter-context" },
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		lazy = false,
		config = function()
			require("nvim-treesitter-textobjects").setup({
				select = {
					enable = true,
					lookahead = true,
					keymaps = {
						["af"] = "@function.outer",
						["if"] = "@function.inner",
					},
				},
			})
		end,
	},
}
