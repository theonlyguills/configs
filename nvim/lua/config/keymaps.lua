vim.keymap.set("n", "<leader>fs", function() 
	require('telescope.builtin').find_files({ hidden = true })
	end, { desc = "Find files including dotfiles" })
vim.keymap.set("n", "<leader>fp", ":Telescope git_files<cr>")
vim.keymap.set("n", "<leader>fz", ":Telescope live_grep<cr>")
vim.keymap.set("n", "<leader>fo", ":Telescope oldfiles<cr>")

vim.keymap.set("n", "<leader>e", ":NvimTreeFindFileToggle<cr>")

vim.keymap.set({"n", "v"}, "<leader>/", ":CommentToggle<cr>")


