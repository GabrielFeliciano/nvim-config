-- some init configs
vim.keymap.set({"n", "i"}, "<C-h>", function() print("hello") end)
-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true
vim.opt.relativenumber = true

vim.keymap.set({"n", "i"}, "<leader>gg", ":LazyGit<CR>")

-- lazy
require("config.lazy")

-- default config netrw
require("netrw").setup({})

-- "tree navigation"
require('mini.files').setup()

-- make gitlazy plugin open files in current nvim
function EditLineFromLazygit(file_path, line)
    local path = vim.fn.expand("%:p")
    if path == file_path then
        vim.cmd(tostring(line))
    else
        vim.cmd("e " .. file_path)
        vim.cmd(tostring(line))
    end
end

function EditFromLazygit(file_path)
    local path = vim.fn.expand("%:p")
    if path == file_path then
        return
    else
        vim.cmd("e " .. file_path)
    end
end

