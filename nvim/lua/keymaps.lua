vim.g.mapleader = " "

-- Yank to system clipboard
vim.keymap.set("n", "y", '"+y')
vim.keymap.set("v", "y", '"+y')

-- Paste from system clipboard
vim.keymap.set("n", "p", '"+p')
vim.keymap.set("v", "p", '"+p')
vim.keymap.set("n", "P", '"+P')
vim.keymap.set("v", "P", '"+P')

-- Close current buffer and its window
vim.keymap.set("n", "<leader>q", ":bd<CR>", { silent = true })

