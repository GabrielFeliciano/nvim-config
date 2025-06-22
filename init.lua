-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- general configs 
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.splitright = true;
vim.opt.clipboard = 'unnamedplus'
vim.o.scrolloff = 6

vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  callback = function()
    vim.cmd("wincmd L") -- Move help window to the right
  end,
})

-- lazy
require("config.lazy")
vim.keymap.set({"n", "i"}, "<leader>gg", ":LazyGit<CR>")

-- Mason
local Mason = require("mason")
Mason.setup()

-- default config netrw
require("netrw").setup({})

-- "tree navigation"
require('mini.files').setup()
vim.keymap.set({"n"}, "<leader>t", MiniFiles.open)

-- Toggle zen mode
local zenmode = require("zen-mode")
zenmode.setup({
	on_open = function(_)
		vim.cmd("cabbrev <buffer> q let b:quitting = 1 <bar> q")
		vim.cmd("cabbrev <buffer> wq let b:quitting = 1 <bar> wq")
	end,
	on_close = function()
		if vim.b.quitting == 1 then
			vim.b.quitting = 0
			vim.cmd("q")
		end
	end,
})
vim.keymap.set("n", "<leader>tz", zenmode.toggle, { desc = "Toggle zen mode" })
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		require("zen-mode").toggle()
	end,
})

-- lsp

-- Telescope
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })

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

