return {
	"simrat39/rust-tools.nvim",
	lazy = true,
	opts = function()
		local ok, mason_registry = pcall(require, "mason-registry")
		local adapter ---@type any
		if ok and mason_registry.has_package("codelldb") then
			local ok_pkg, codelldb = pcall(mason_registry.get_package, "codelldb")
			if ok_pkg and codelldb:is_installed() then
				local extension_path = codelldb:get_install_path() .. "/extension/"
				local codelldb_path = extension_path .. "adapter/codelldb"
				local is_win = vim.fn.has("win32") == 1
				local liblldb_path = ""
				if is_win then
					liblldb_path = extension_path .. "lldb/bin/liblldb.dll"
				elseif vim.fn.has("mac") == 1 then
					liblldb_path = extension_path .. "lldb/lib/liblldb.dylib"
				else
					liblldb_path = extension_path .. "lldb/lib/liblldb.so"
				end
				pcall(function()
					adapter = require("rust-tools.dap").get_codelldb_adapter(codelldb_path, liblldb_path)
				end)
			end
		end
		return {
			dap = {
				adapter = adapter,
			},
			tools = {
				on_initialized = function()
					vim.cmd([[
                augroup RustLSP
                  autocmd CursorHold                      *.rs silent! lua vim.lsp.buf.document_highlight()
                  autocmd CursorMoved,InsertEnter         *.rs silent! lua vim.lsp.buf.clear_references()
                  autocmd BufEnter,CursorHold,InsertLeave *.rs silent! lua vim.lsp.codelens.refresh()
                augroup END
              ]])
				end,
			},
		}
	end,
	config = function() end,
}
