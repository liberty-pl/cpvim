-- Bootstrap lazy.nvim, LazyVim, and the competitive-programming plugins.
-- Machine-specific settings stay outside Git and load before plugin specs.
local local_config = vim.fs.joinpath(vim.fn.stdpath("config"), "local.lua")
if vim.fn.filereadable(local_config) == 1 then
  dofile(local_config)
end
require("config.lazy")
