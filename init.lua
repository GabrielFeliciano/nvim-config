require("config.lazy")

-- some init configs
vim.keymap.set({"n", "i"}, "<C-h>", function() print("hello") end)
-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true
vim.opt.relativenumber = true

-- default config netrw
require("netrw").setup({})

-- "tree navigation"
require('mini.files').setup()

vim.keymap.set({"n", "i"}, "<leader>gg", ":LazyGit<CR>")


