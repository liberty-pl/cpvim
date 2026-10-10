return {
  {
    "mistricky/codesnap.nvim",
    tag = "v2.0.5",
    cmd = {
      "CodeSnap",
      "CodeSnapSave",
    },
    keys = {
      {
        "<leader>yc",
        ":CodeSnap<cr>",
        mode = "x",
        desc = "复制代码截图",
      },
      { "<leader>ys", ":CodeSnapSave ", mode = "x", desc = "保存代码截图" },
    },
    config = function()
      -- plugin/codesnap.lua is sourced before Lazy runs this config and
      -- CodeSnap v2.0.5 leaves its concrete generator .so in package.cpath.
      -- A later require for any native module could then open the wrong .so.
      local loaded, codesnap = pcall(require, "codesnap")
      local clean_cpath = {}
      for entry in package.cpath:gmatch("[^;]+") do
        if not entry:find("codesnap.nvim", 1, true) then
          table.insert(clean_cpath, entry)
        end
      end
      package.cpath = table.concat(clean_cpath, ";")
      if not loaded then
        error(codesnap)
      end
      codesnap.setup({
        snapshot_config = {
          theme = "kanagawa",
          themes_folders = {
            vim.fn.stdpath("data") .. "/lazy/kanagawa/extras/tmTheme",
          },
          line_number_color = "#727169",
          window = {
            border = { color = "#54546D" },
            title_config = { color = "#DCD7BA" },
          },
          watermark = { color = "#C8C093" },
          background = {
            stops = {
              { position = 0, color = "#16161D" },
              { position = 1, color = "#2D4F67" },
            },
          },
        },
      })
      pcall(vim.api.nvim_del_user_command, "CodeSnap")
      vim.api.nvim_create_user_command("CodeSnap", function()
        require("config.codesnap-clipboard").copy()
      end, { range = "%", desc = "复制代码截图" })
    end,
  },
}
