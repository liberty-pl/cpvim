local cp_group = vim.api.nvim_create_augroup("competitive_programming", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = cp_group,
  pattern = { "c", "cpp" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.expandtab = true
    vim.opt_local.colorcolumn = "100"
  end,
})

-- Show diagnostics while editing, but keep virtual text focused on warnings and errors.
vim.api.nvim_create_autocmd("User", {
  group = cp_group,
  pattern = "VeryLazy",
  callback = function()
    vim.diagnostic.config({
      underline = true,
      update_in_insert = true,
      severity_sort = true,
      signs = true,
      virtual_text = {
        severity = { min = vim.diagnostic.severity.WARN },
        spacing = 4,
        source = "if_many",
        prefix = "●",
      },
      float = {
        border = "rounded",
        source = true,
      },
    })
  end,
})
