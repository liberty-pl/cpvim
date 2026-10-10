-- Options are loaded before lazy.nvim starts loading plugins.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.g.autoformat = true

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.wrap = false
vim.opt.scrolloff = 6
vim.opt.sidescrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 200
vim.opt.timeoutlen = 300
vim.opt.clipboard = "unnamedplus"
-- 保留 Tab/不间断空格提示，但不要把正在输入的行尾空格画成横线。
vim.opt.listchars = { tab = "> ", nbsp = "+" }
vim.opt.splitbelow = true
vim.opt.splitright = true
