return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"folke/neodev.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			"stevearc/conform.nvim",
			"b0o/SchemaStore.nvim",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/nvim-cmp",
			"L3MON4D3/LuaSnip",
			"saadparwaiz1/cmp_luasnip",
			"j-hui/fidget.nvim",
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		lazy = false,
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			-- Neodev setup
			require("neodev").setup()

			-- Diagnostic signs
			local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
			for type, icon in pairs(signs) do
				vim.fn.sign_define(
					"DiagnosticSign" .. type,
					{ text = icon, texthl = "DiagnosticSign" .. type, numhl = "" }
				)
			end

			-- Capabilities
			local capabilities = vim.lsp.protocol.make_client_capabilities()

			-- Add nvim-cmp capabilities properly
			if pcall(require, "cmp_nvim_lsp") then
				capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
			end

			-- Ensure labelDetails support is enabled (this is what rust-analyzer needs)
			capabilities.textDocument.completion.completionItem.labelDetailsSupport = true
			capabilities.textDocument.completion.completionItem.snippetSupport = true

			-- Specifically for rust-analyzer, add these capabilities
			capabilities.textDocument.completion.completionItem.resolveSupport = {
				properties = { "documentation", "detail", "additionalTextEdits" },
			}
			-- Keymaps
			local opts = { noremap = true, silent = true }
			local on_attach = function(client, bufnr)
				print(client.name)
				opts.buffer = bufnr

				-- Navigation
				opts.desc = "Go to definition"
				vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
				opts.desc = "Go to declaration"
				vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
				opts.desc = "Go to implementation"
				vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
				opts.desc = "Go to type definition"
				vim.keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)
				opts.desc = "Go to references"
				vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				opts.desc = "Go to references (Telescope)"
				vim.keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)
				opts.desc = "Hover documentation"
				vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

				-- Actions
				opts.desc = "Code action"
				vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
				opts.desc = "Rename symbol"
				vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

				-- Diagnostics
				opts.desc = "Show line diagnostics"
				vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
				opts.desc = "Show buffer diagnostics (Telescope)"
				vim.keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)
				vim.keymap.set("n", "[d", function()
					vim.diagnostic.jump({ count = 1, float = true })
				end, { buffer = bufnr, desc = "Next diagnostic" })
				vim.keymap.set("n", "]d", function()
					vim.diagnostic.jump({ count = -1, float = true })
				end, { buffer = bufnr, desc = "Previous diagnostic" })

				-- Workspace
				opts.desc = "Workspace symbol"
				vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
				opts.desc = "Add workspace folder"
				vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts)
				opts.desc = "Remove workspace folder"
				vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts)
				opts.desc = "List workspace folders"
				vim.keymap.set("n", "<leader>wl", vim.lsp.buf.list_workspace_folders, opts)

				-- Misc
				opts.desc = "Restart LSP"
				vim.keymap.set("n", "<leader>rs", ":lsp restart<CR>", opts)
				opts.desc = "Signature help"
				vim.keymap.set("i", "<C-s>", vim.lsp.buf.signature_help, opts)
				-- vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
			end

			-- Server configurations
			local servers = {
				bashls = true,
				lua_ls = true,
				gopls = false,
				rust_analyzer = {
					-- This is crucial for completions like String::
					settings = {
						["rust-analyzer"] = {
							-- Enable all completion features
							completion = {
								autoimport = {
									enable = true,
								},
								fullFunctionSignatures = {
									enable = true,
								},
								postfix = {
									enable = true,
								},
								-- snippets = { enable = true },
							},
							assist = {
								importGranularity = "module",
								importPrefix = "self",
							},
							-- Enable experimental completions
							experimental = {
								completions = { enable = true },
							},
							-- Ensure cargo features are enabled
							cargo = {
								features = "all",
								noDefaultFeatures = false,
							},
							-- Ensure imports are added automatically
							imports = {
								granularity = {
									group = "module",
								},
								prefix = "self",
								merge = {
									glob = true,
								},
							},
							-- Enable call info for completions
							callInfo = {
								enable = true,
							},
							-- Enable inlay hints if you want them
							inlayHints = {
								chainingHints = true,
								maxLength = 25,
								parameterHints = true,
								typeHints = true,
							},
						},
					},
				},
				templ = true,
				cssls = true,
				htmx = true,
				pyright = true,
				ts_ls = true,
				tailwindcss = true,
				eslint = true,
				intelephense = true,
				jsonls = {
					settings = {
						json = {
							schemas = {
								{
									fileMatch = { ".prettierrc", "package.json" },
									url = "https://json.schemastore.org/prettierrc",
								},
								{
									fileMatch = { "package.json" },
									url = "https://json.schemastore.org/package",
								},
								{
									fileMatch = { ".eslintrc", ".eslintrc.json" },
									url = "https://json.schemastore.org/eslintrc",
								},
								require("schemastore").json.schemas(),
							},
						},
					},
				},
				svelte = {
					on_attach = function(client, bufnr)
						on_attach(client, bufnr)
						vim.api.nvim_create_autocmd("BufWritePost", {
							pattern = { "*.js", "*.ts" },
							callback = function(ctx)
								if client.name == "svelte" then
									client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.file })
								end
							end,
						})
					end,
				},
				slint_lsp = {
					on_attach = function(client, bufnr)
						on_attach(client, bufnr)
						vim.api.nvim_create_autocmd("BufNewFile", {
							pattern = "*.slint",
							callback = function()
								vim.cmd("set filetype=slint")
							end,
						})
					end,
				},
				zls = {
					root_dir = require("lspconfig.util").root_pattern(".git", "build.zig", "zls.json"),
					settings = { zls = { enable_inlay_hints = true, enable_snippets = true, warn_style = true } },
				},
				html = {
					cmd = { "vscode-html-language-server", "--stdio" },
					filetypes = { "html" },
					init_options = {
						configurationSection = { "html", "css", "javascript" },
						embeddedLanguages = { css = true, javascript = true },
					},
				},
				-- omnisharp = {
				--     cmd = {
				--         "dotnet",
				--         vim.fn.stdpath("data") .. "/mason/packages/omnisharp/libexec/OmniSharp.dll",
				--         "--languageserver",
				--         "--hostPID", tostring(vim.fn.getpid()),
				--         "--verbose",
				--     },
				--     root_dir = function(fname)
				--         return require("lspconfig.util").root_pattern("*.sln", "*.csproj")(fname)
				--             or require("lspconfig.util").find_git_ancestor(fname)
				--             or vim.fn.getcwd()
				--     end,
				-- },
				ocamllsp = {
					manual_install = true,
					settings = { codelens = { enable = true } },
					filetypes = { "ocaml", "ocaml.interface", "ocaml.menhir", "ocaml.cram" },
				},
				clangd = {
					init_options = { clangdFileStatus = true },
					filetypes = { "c", "cpp" },
				},
			}
			-- Setup Mason and install tools
			require("fidget").setup()
			require("mason").setup({
				registries = {
					"github:Crashdummyy/mason-registry", -- ✅ Corrected address
					"github:mason-org/mason-registry", -- Keep the default registry
				},
			})

			local servers_to_install = vim.tbl_filter(function(name)
				local config = servers[name]
				return config ~= false and (type(config) ~= "table" or not config.manual_install)
			end, vim.tbl_keys(servers))
			local ensure_installed = {
				"stylua",
				"lua_ls",
			}

			vim.list_extend(ensure_installed, servers_to_install)
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			-- Setup LSP servers
			for name, config in pairs(servers) do
				if config == false then
					goto continue
				end

				config = config == true and {} or config

				config = vim.tbl_deep_extend("force", {
					capabilities = capabilities,
					on_attach = on_attach,
				}, config)

				vim.lsp.config(name, config)
				vim.lsp.enable(name)

				::continue::
			end
			-- roslyn.nvim
			vim.lsp.config("roslyn", {
				capabilities = capabilities,
				on_attach = on_attach,
				filetypes = { "cs", "razor", "cshtml" },
				settings = {
					["csharp|inlay_hints"] = {
						csharp_enable_inlay_hints_for_implicit_object_creation = true,
						csharp_enable_inlay_hints_for_implicit_variable_types = true,
						csharp_enable_inlay_hints_for_lambda_parameter_types = true,
						csharp_enable_inlay_hints_for_types = true,
					},
					["csharp|code_lens"] = {
						dotnet_enable_references_code_lens = true,
						dotnet_enable_tests_code_lens = true,
					},
					["csharp|completion"] = {
						dotnet_show_completion_items_from_unimported_namespaces = true,
						dotnet_show_name_completion_suggestions = true,
					},
					["csharp|background_analysis"] = {
						dotnet_analyzer_diagnostics_scope = "openfiles",
						dotnet_compiler_diagnostics_scope = "openfiles",
					},
				},
			})
			vim.lsp.enable("roslyn")
			-- rust_analyzer
			-- vim.lsp.config.rust_analyzer = {
			--     cmd = { "rust-analyzer" },
			--     settings = { ["rust-analyzer"] = { completion = { autoimport = { enable = true } } } }
			-- }
			-- vim.lsp.enable("rust_analyzer")

			require("conform").setup({
				formatters_by_ft = { lua = { "stylua" } },
			})

			vim.api.nvim_create_autocmd("BufWritePre", {
				callback = function(args)
					require("conform").format({ bufnr = args.buf, lsp_fallback = true, quiet = true })
				end,
			})
		end,
	},
}
