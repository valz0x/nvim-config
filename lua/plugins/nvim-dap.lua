return {
	{ "nvim-lua/popup.nvim" },
	{ "nvim-neotest/nvim-nio" },
	{ "nvim-lua/plenary.nvim" },
	{
		"tomblind/local-lua-debugger-vscode",
		config = function() end,
	},
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"leoluz/nvim-dap-go",
			"theHamsta/nvim-dap-virtual-text",
			"nvim-neotest/nvim-nio",
			"williamboman/mason.nvim",
			"mxsdev/nvim-dap-vscode-js",
		},
		config = function()
			local dap = require("dap")
			local ok_dapui, dapui = pcall(require, "dapui")

			if ok_dapui then
				dapui.setup({
					icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
					mappings = {
						expand = { "<CR>", "<2-LeftMouse>" },
						open = "o",
						remove = "d",
						edit = "e",
						repl = "r",
						toggle = "t",
					},
					layouts = {
						{
							elements = {
								{ id = "scopes", size = 0.25 },
								"breakpoints",
								"stacks",
								"watches",
							},
							size = 40,
							position = "left",
						},
						{
							elements = {
								"repl",
								"console",
							},
							size = 0.25,
							position = "bottom",
						},
					},
					floating = {
						max_height = nil,
						max_width = nil,
						border = "rounded",
						mappings = {
							close = { "q", "<Esc>" },
						},
					},
					windows = { indent = 1 },
				})

				-- Auto open/close dap-ui with sessions
				dap.listeners.after.event_initialized["dapui_config"] = function()
					dapui.open()
				end
				dap.listeners.before.event_terminated["dapui_config"] = function()
					dapui.close()
				end
				dap.listeners.before.event_exited["dapui_config"] = function()
					dapui.close()
				end
			end

			-- Virtual text
			local ok_vt, dap_vt = pcall(require, "nvim-dap-virtual-text")
			if ok_vt then
				dap_vt.setup({
					display_callback = function(variable)
						local name = string.lower(variable.name)
						local value = string.lower(variable.value or "")
						if name:match("secret") or name:match("api") or name:match("password") or name:match("token") then
							return " = [REDACTED]"
						end
						if #variable.value > 40 then
							return " = " .. string.sub(variable.value, 1, 40) .. "..."
						end
						return " = " .. variable.value
					end,
				})
			end

			-- ============================================================================
			-- C# / .NET Debugging (netcoredbg)
			-- ============================================================================
			local function find_netcoredbg()
				local from_path = vim.fn.exepath("netcoredbg")
				if from_path ~= "" then
					return from_path
				end
				local is_win = vim.fn.has("win32") == 1
				local mason_bin = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin", "netcoredbg" .. (is_win and ".cmd" or ""))
				if vim.fn.executable(mason_bin) == 1 then
					return mason_bin
				end
				local mason_pkg = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages", "netcoredbg", "netcoredbg", "netcoredbg" .. (is_win and ".exe" or ""))
				if vim.fn.executable(mason_pkg) == 1 then
					return mason_pkg
				end
				if is_win then
					local scoop_path = vim.fs.joinpath(vim.env.USERPROFILE or "", "scoop", "shims", "netcoredbg.exe")
					if vim.fn.executable(scoop_path) == 1 then
						return scoop_path
					end
				end
				return "netcoredbg"
			end

			dap.adapters.coreclr = {
				type = "executable",
				command = find_netcoredbg(),
				args = { "--interpreter=vscode" },
			}

			local function find_dotnet_dll()
				local cwd = vim.fn.getcwd()
				local debug_dlls = vim.fn.glob(cwd .. "/bin/Debug/**/*.dll", false, true)
				if #debug_dlls > 0 then
					for _, dll in ipairs(debug_dlls) do
						if not dll:match("%.Views%.dll$") and not dll:match("%.resources%.dll$") then
							return dll
						end
					end
					return debug_dlls[1]
				end
				local release_dlls = vim.fn.glob(cwd .. "/bin/Release/**/*.dll", false, true)
				if #release_dlls > 0 then
					return release_dlls[1]
				end
				return vim.fn.input("Path to dll: ", cwd .. "/bin/Debug/", "file")
			end

			dap.configurations.cs = {
				{
					type = "coreclr",
					name = "Launch .NET (Auto-detect / prompt DLL)",
					request = "launch",
					program = find_dotnet_dll,
					cwd = "${workspaceFolder}",
					stopAtEntry = false,
				},
				{
					type = "coreclr",
					name = "Launch .NET WebAPI (Development)",
					request = "launch",
					program = find_dotnet_dll,
					cwd = "${workspaceFolder}",
					env = {
						ASPNETCORE_ENVIRONMENT = "Development",
						ASPNETCORE_URLS = "http://localhost:5000",
					},
					stopAtEntry = false,
				},
				{
					type = "coreclr",
					name = "Attach to .NET process",
					request = "attach",
					processId = require("dap.utils").pick_process,
				},
			}

			-- ============================================================================
			-- Rust, C, C++ Debugging (lldb-dap / lldb-vscode / codelldb)
			-- ============================================================================
			local lldb_dap = vim.fn.exepath("lldb-dap")
			if lldb_dap == "" then
				lldb_dap = vim.fn.exepath("lldb-vscode")
			end
			if lldb_dap == "" and vim.fn.has("win32") == 1 then
				local scoop_lldb = vim.fs.joinpath(vim.env.USERPROFILE or "", "scoop", "apps", "llvm", "current", "bin", "lldb-dap.exe")
				if vim.fn.executable(scoop_lldb) == 1 then
					lldb_dap = scoop_lldb
				end
			end

			local is_win = vim.fn.has("win32") == 1
			local codelldb_bin = vim.fn.exepath("codelldb")
			if codelldb_bin == "" then
				local mason_codelldb = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin", "codelldb" .. (is_win and ".cmd" or ""))
				if vim.fn.executable(mason_codelldb) == 1 then
					codelldb_bin = mason_codelldb
				end
			end

			if lldb_dap ~= "" then
				dap.adapters.lldb = {
					type = "executable",
					command = lldb_dap,
					name = "lldb-dap",
				}
				dap.adapters.codelldb = dap.adapters.lldb
			elseif codelldb_bin ~= "" then
				dap.adapters.codelldb = {
					type = "server",
					port = "${port}",
					executable = {
						command = codelldb_bin,
						args = { "--port", "${port}" },
					},
				}
				dap.adapters.lldb = dap.adapters.codelldb
			else
				dap.adapters.lldb = {
					type = "executable",
					command = "lldb-dap",
					name = "lldb-dap",
				}
				dap.adapters.codelldb = dap.adapters.lldb
			end

			local function find_native_executable()
				local cwd = vim.fn.getcwd()
				if is_win then
					local rust_bins = vim.fn.glob(cwd .. "/target/debug/*.exe", false, true)
					if #rust_bins > 0 then
						return rust_bins[1]
					end
				else
					local rust_bins = vim.fn.glob(cwd .. "/target/debug/*", false, true)
					for _, b in ipairs(rust_bins) do
						if not b:match("%.[dr]$") and not b:match("%.rlib$") and not b:match("%.so$") and vim.fn.executable(b) == 1 then
							return b
						end
					end
				end
				return vim.fn.input("Path to executable: ", cwd .. "/", "file")
			end

			local native_config = {
				{
					name = "Launch executable",
					type = dap.adapters.lldb and "lldb" or "codelldb",
					request = "launch",
					program = find_native_executable,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
				},
				{
					name = "Attach to process",
					type = dap.adapters.lldb and "lldb" or "codelldb",
					request = "attach",
					pid = require("dap.utils").pick_process,
				},
			}

			dap.configurations.rust = native_config
			dap.configurations.c = native_config
			dap.configurations.cpp = native_config

			-- ============================================================================
			-- Go Debugging
			-- ============================================================================
			local ok_dap_go, dap_go = pcall(require, "dap-go")
			if ok_dap_go then
				dap_go.setup()
			end

			-- ============================================================================
			-- JavaScript / TypeScript Debugging
			-- ============================================================================
			local ok_js, dap_js = pcall(require, "dap-vscode-js")
			if ok_js then
				dap_js.setup({
					adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
				})

				for _, language in ipairs({ "typescript", "javascript" }) do
					dap.configurations[language] = {
						{
							type = "pwa-node",
							request = "launch",
							name = "Launch file",
							program = "${file}",
							cwd = "${workspaceFolder}",
						},
						{
							type = "pwa-node",
							request = "attach",
							name = "Attach",
							processId = require("dap.utils").pick_process,
							cwd = "${workspaceFolder}",
						},
					}
				end
			end

			-- ============================================================================
			-- Lua Debugging
			-- ============================================================================
			local lua_dbg = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt", "local-lua-debugger-vscode", "extension", "debugAdapter.js")
			if vim.fn.filereadable(lua_dbg) == 1 then
				dap.adapters["local-lua"] = {
					type = "executable",
					command = "node",
					args = { lua_dbg },
				}
				dap.configurations.lua = {
					{
						name = "Current file (local-lua, lua)",
						type = "local-lua",
						request = "launch",
						cwd = "${workspaceFolder}",
						program = {
							lua = "lua",
							file = "${file}",
						},
					},
				}
			end

			-- ============================================================================
			-- Keymaps
			-- ============================================================================
			local map = vim.keymap.set
			map("n", "<F5>", dap.continue, { desc = "Debug: continue" })
			map("n", "<F10>", dap.step_over, { desc = "Debug: step over" })
			map("n", "<F11>", dap.step_into, { desc = "Debug: step into" })
			map("n", "<F12>", dap.step_out, { desc = "Debug: step out" })
			map("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: toggle breakpoint" })
			map("n", "<leader>B", function()
				dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end, { desc = "Debug: conditional breakpoint" })
			map("n", "<leader>lp", function()
				dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
			end, { desc = "Debug: log point" })
			map("n", "<leader>dr", dap.repl.open, { desc = "Debug: open REPL" })
			map("n", "<leader>dl", dap.run_last, { desc = "Debug: run last" })
			map("n", "<leader>dx", dap.terminate, { desc = "Debug: terminate session" })
			if ok_dapui then
				map("n", "<leader>du", dapui.toggle, { desc = "Debug: toggle UI" })
				map("n", "<space>?", function()
					dapui.eval(nil, { enter = true })
				end, { desc = "Debug: evaluate under cursor" })
			end
		end,
	},
}
