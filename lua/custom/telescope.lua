local data = assert(vim.fn.stdpath("data")) --[[@as string]]

require("telescope").setup({
    extensions = {
        fzf = {},
        ["ui-select"] = {
            require("telescope.themes").get_dropdown({
                -- even more opts
            }),
        },
        wrap_results = true,
        -- history = {
        -- 	path = vim.fs.joinpath(data, "telescope_history.sqlite3"),
        -- 	limit = 100,
        -- },
    },
})

pcall(require("telescope").load_extension, "fzf")
-- pcall(require("telescope").load_extension, "smart_history")
pcall(require("telescope").load_extension, "ui-select")
pcall(require("telescope").load_extension, "noice")
pcall(require("telescope").load_extension, "wrap_results")
local builtin = require("telescope.builtin")

vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Find help tags" })
vim.keymap.set("n", "<leader>gw", builtin.grep_string, { desc = "Grep word under cursor" })
vim.keymap.set("n", "<C-p>", builtin.git_files, { desc = "Find git files" })
vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Find keymaps" })
vim.keymap.set("n", "<leader>ps", function()
    builtin.grep_string({ search = vim.fn.input("Grep > ") })
end, { desc = "Grep for input" })

vim.keymap.set("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "Fuzzy find in current buffer" })

vim.keymap.set("n", "<leader>fa", function()
    local pack_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt")
    local search_dir = vim.fn.isdirectory(pack_dir) == 1 and pack_dir or vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")
    builtin.find_files({ cwd = search_dir })
end, { desc = "Find files in installed plugins" })

vim.keymap.set("n", "<space>en", function()
    builtin.find_files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Find files in nvim config" })
