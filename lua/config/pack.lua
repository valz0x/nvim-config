local M = {}

local plugin_files = {
	"plenary",
	"colorscheme",
	"fidget",
	"nvim-cmp",
	"lsp-config",
	"telescope",
	"treesitter",
	"autopair",
	"alpha-nvim",
	"autosession",
	"bufferline",
	"cellular-auto",
	"comment",
	"copilot",
	"dadbod",
	"dbee",
	"gotopreview",
	"harpoon",
	"hop",
	"inden-blanline",
	"lualine",
	"mini",
	"neo-tree",
	"noice",
	"none-ls",
	"nvim-dap",
	"nvim-surround",
	"obisidian",
	"oil",
	"refactoring",
	"roslyn",
	"rust-tools",
	"sourcegraph",
	"statusline",
	"supermaven",
	"toggleterm",
	"troubletoggle",
	"undotree",
	"vim-fugitive",
	"vimwithme",
	"which-key",
	"zenmode",
}

local function gh(repo)
	if repo:match("^[%w+.-]+://") or repo:match("^git@") then
		return repo
	end

	return "https://github.com/" .. repo
end

local function plugin_name(src)
	return src:gsub("%.git$", ""):match("[^/]+$")
end

local function plugin_version(spec)
	local version = spec.version or spec.tag or spec.branch or spec.commit
	if version == "*" then
		return nil
	end

	return version
end

local function module_name(spec)
	return spec.main or (spec.name or plugin_name(spec[1] or spec.src)):gsub("%.nvim$", ""):gsub("%.vim$", "")
end

local function as_list(value)
	if value == nil then
		return {}
	end

	if type(value) == "string" then
		return { value }
	end

	if value[1] ~= nil then
		return value
	end

	return { value }
end

local specs = {}
local pack_specs = {}
local pack_seen = {}
local build_hooks = {}

local function add_pack_spec(spec)
	local src = spec.src or spec[1]
	if type(src) ~= "string" then
		return
	end

	local pack_spec = {
		src = gh(src),
		name = spec.name,
		version = plugin_version(spec),
	}
	local name = pack_spec.name or plugin_name(pack_spec.src)

	if not pack_seen[name] then
		pack_seen[name] = true
		pack_specs[#pack_specs + 1] = pack_spec
	end

	if spec.build then
		build_hooks[name] = spec.build
	end
end

local function collect(spec)
	if type(spec) == "string" then
		add_pack_spec({ spec })
		return
	end

	if type(spec) ~= "table" then
		return
	end

	if type(spec[1]) == "string" then
		specs[#specs + 1] = spec
		add_pack_spec(spec)

		for _, dep in ipairs(as_list(spec.dependencies)) do
			collect(dep)
		end
		return
	end

	for _, child in ipairs(spec) do
		collect(child)
	end
end

for _, file in ipairs(plugin_files) do
	local ok, plugin_spec = pcall(require, "plugins." .. file)
	if ok then
		collect(plugin_spec)
	else
		vim.notify(("Failed to load plugin spec %s: %s"):format(file, plugin_spec), vim.log.levels.ERROR)
	end
end

local function run_build_hook(hook, path)
	if type(hook) == "function" then
		hook()
	elseif type(hook) == "string" then
		if hook:sub(1, 1) == ":" then
			vim.cmd(hook:sub(2))
		else
			vim.system(vim.split(hook, " "), { cwd = path }):wait()
		end
	end
end

function M.setup()
	if not vim.pack then
		vim.notify("vim.pack API is required for this config (Neovim 0.12+). Please use Neovim 0.12+ / nightly on Arch.", vim.log.levels.WARN)
		return
	end

	vim.api.nvim_create_user_command("PackAdd", function(opts)
		vim.pack.add(opts.fargs)
	end, { desc = "Add a plugin", nargs = "+" })

	vim.api.nvim_create_user_command("PackUpdate", function(opts)
		if opts.args ~= "" then
			local plugins = vim.split(opts.args, "%s+", { trimempty = true })
			vim.pack.update(plugins)
		else
			vim.pack.update()
		end
	end, { desc = "Update all plugins or specific ones", nargs = "*" })
	vim.api.nvim_create_autocmd("PackChanged", {
		callback = function(ev)
			if ev.data.kind ~= "install" and ev.data.kind ~= "update" then
				return
			end

			local hook = build_hooks[ev.data.spec.name]
			if hook then
				run_build_hook(hook, ev.data.path)
			end
		end,
	})

	vim.pack.add(pack_specs)

	for _, spec in ipairs(pack_specs) do
		pcall(vim.cmd.packadd, spec.name or plugin_name(spec.src))
	end

	for _, spec in ipairs(specs) do
		local ok, err = pcall(function()
			if type(spec.init) == "function" then
				spec.init()
			end

			if type(spec.config) == "function" then
				spec.config(spec, spec.opts)
			elseif spec.config == true or spec.opts ~= nil then
				require(module_name(spec)).setup(spec.opts or {})
			end
		end)

		if not ok then
			vim.notify(("Failed to configure %s: %s"):format(spec.name or spec[1], err), vim.log.levels.ERROR)
		end
	end
end

return M
