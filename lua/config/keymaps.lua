-- 大部分快捷键由 LazyVim 或 lua/plugins/ 中的插件配置提供。
-- 这里只放置全局通用且不属于某个插件的快捷键。
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "清除搜索高亮" })
vim.keymap.set("i", "jk", "<Esc>", { desc = "返回普通模式" })
