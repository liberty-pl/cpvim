return {
  {
    "catppuccin/nvim",
    enabled = false,
  },
  {
    "folke/tokyonight.nvim",
    enabled = false,
  },
  {
    "rebelot/kanagawa.nvim",
    name = "kanagawa",
    priority = 1000,
    opts = {
      compile = false,
      undercurl = true,
      commentStyle = { italic = true },
      keywordStyle = { italic = true },
      statementStyle = { bold = true },
      transparent = false,
      dimInactive = false,
      terminalColors = true,
      theme = "wave",
      background = { dark = "wave", light = "lotus" },
      overrides = function(colors)
        local palette = colors.palette
        return {
          SnacksDashboardHeader = { fg = palette.crystalBlue, bold = true },
          SnacksDashboardIcon = { fg = palette.springViolet1 },
          SnacksDashboardKey = { fg = palette.carpYellow, bold = true },
          SnacksDashboardDesc = { fg = palette.oldWhite },
          SnacksDashboardFooter = { fg = palette.fujiGray, italic = true },
          SnacksPicker = { fg = palette.fujiWhite, bg = palette.sumiInk3 },
          SnacksPickerBox = { link = "SnacksPicker" },
          SnacksPickerInput = { link = "SnacksPicker" },
          SnacksPickerList = { link = "SnacksPicker" },
          SnacksPickerPreview = { link = "SnacksPicker" },
          SnacksPickerMatch = { fg = palette.springGreen, bold = true },
          SnacksPickerPrompt = { fg = palette.crystalBlue, bold = true },
          SnacksPickerBorder = { fg = palette.sumiInk6, bg = palette.sumiInk3 },
          SnacksPickerTitle = { fg = palette.carpYellow, bg = palette.sumiInk3, bold = true },
          WhichKey = { fg = palette.crystalBlue, bold = true },
          WhichKeyGroup = { fg = palette.carpYellow },
          WhichKeyDesc = { fg = palette.oldWhite },
          WhichKeySeparator = { fg = palette.fujiGray },
          WhichKeyNormal = { bg = palette.sumiInk0 },
          WhichKeyBorder = { fg = palette.sumiInk6, bg = palette.sumiInk0 },
          WhichKeyTitle = { fg = palette.carpYellow, bg = palette.sumiInk0, bold = true },
          StatusLine = { fg = palette.oldWhite, bg = palette.sumiInk3 },
          StatusLineNC = { fg = palette.fujiGray, bg = palette.sumiInk3 },
        }
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    keys = {
      {
        "<leader>ya",
        function()
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          local text = table.concat(lines, "\n")
          if vim.bo.endofline then
            text = text .. "\n"
          end
          vim.fn.setreg("+", text, "v")
          vim.notify("已复制当前文件的全部代码", vim.log.levels.INFO, { title = "剪贴板" })
        end,
        desc = "复制整个文件（纯文本）",
      },
    },
    opts = {
      colorscheme = "kanagawa-wave",
    },
  },
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>e",
        function()
          Snacks.explorer()
        end,
        desc = "文件浏览器（当前目录）",
      },
      {
        "<leader>E",
        function()
          Snacks.explorer({ cwd = LazyVim.root() })
        end,
        desc = "文件浏览器（项目根目录）",
      },
    },
    opts = function(_, opts)
      opts.dashboard = opts.dashboard or {}
      opts.dashboard.preset = opts.dashboard.preset or {}
      opts.dashboard.preset.header = [[
 ██████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
██╔════╝ ██╔══██╗██║   ██║██║████╗ ████║
██║      ██████╔╝██║   ██║██║██╔████╔██║
██║      ██╔═══╝ ╚██╗ ██╔╝██║██║╚██╔╝██║
╚██████╗ ██║      ╚████╔╝ ██║██║ ╚═╝ ██║
 ╚═════╝ ╚═╝       ╚═══╝  ╚═╝╚═╝     ╚═╝
          ]]
      opts.dashboard.preset.keys = {
        {
          icon = " ",
          key = "c",
          desc = "开始比赛",
          action = ":lua require('config.cp-workspace').start_contest()",
        },
        {
          icon = " ",
          key = "p",
          desc = "开始练习",
          action = ":lua require('config.cp-workspace').start_practice()",
        },
        { icon = " ", key = "f", desc = "查找文件", action = ":lua Snacks.dashboard.pick('files')" },
        { icon = " ", key = "n", desc = "新建文件", action = ":ene | startinsert" },
        { icon = "󰔂 ", key = "o", desc = "选择项目", action = ":lua Snacks.picker.projects()" },
        { icon = " ", key = "g", desc = "全文搜索", action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = " ", key = "r", desc = "最近文件", action = ":lua Snacks.dashboard.pick('oldfiles')" },
        {
          icon = " ",
          key = "d",
          desc = "最近打开目录",
          action = ":lua require('config.cp-workspace').open_recent_directory()",
        },
        {
          icon = " ",
          key = "v",
          desc = "编辑配置",
          action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
        },
        { icon = " ", key = "s", desc = "恢复会话", section = "session" },
        { icon = " ", key = "x", desc = "LazyVim 扩展", action = ":LazyExtras" },
        { icon = "󰂲 ", key = "l", desc = "插件管理", action = ":Lazy" },
        { icon = " ", key = "q", desc = "退出 Neovim", action = ":qa" },
      }

      opts.notifier = vim.tbl_deep_extend("force", opts.notifier or {}, {
        enabled = true,
        timeout = 3000,
      })
      opts.picker = vim.tbl_deep_extend("force", opts.picker or {}, {
        enabled = true,
        sources = {
          buffers = { title = "缓冲区" },
          diagnostics = { title = "诊断信息" },
          explorer = { title = "文件浏览器" },
          files = { title = "查找文件" },
          grep = { title = "全文搜索" },
          lines = { title = "搜索当前文件" },
          lsp_symbols = { title = "文档符号" },
          lsp_workspace_symbols = { title = "工作区符号" },
          notifications = { title = "通知历史" },
          projects = { title = "项目" },
          recent = { title = "最近文件" },
        },
      })
      opts.explorer = vim.tbl_deep_extend("force", opts.explorer or {}, {
        enabled = true,
      })
    end,
  },
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      local descriptions = require("config.which-key-zh")

      opts.replace = opts.replace or {}
      opts.replace.desc = opts.replace.desc or {}
      table.insert(opts.replace.desc, function(desc)
        return descriptions[desc] or desc
      end)

      opts.spec = opts.spec or {}
      vim.list_extend(opts.spec, {
        {
          mode = { "n", "x" },
          { "<leader><tab>", group = "标签页" },
          { "<leader>b", group = "缓冲区" },
          { "<leader>c", group = "代码" },
          { "<leader>d", group = "调试" },
          { "<leader>dp", group = "性能分析" },
          { "<leader>f", group = "文件/查找" },
          { "<leader>g", group = "Git" },
          { "<leader>gh", group = "Git 变更" },
          { "<leader>j", group = "编译/评测" },
          { "<leader>q", group = "退出/会话" },
          { "<leader>s", group = "搜索" },
          { "<leader>u", group = "界面" },
          { "<leader>w", group = "窗口" },
          { "<leader>x", group = "诊断/快速修复" },
          { "<leader>y", group = "复制/代码截图" },
          { "[", group = "上一个" },
          { "]", group = "下一个" },
          { "g", group = "跳转" },
          { "gs", group = "环绕操作" },
          { "z", group = "折叠" },
        },
      })
    end,
  },
  {
    "akinsho/bufferline.nvim",
    opts = function(_, opts)
      local palette = require("kanagawa.colors").setup({ theme = "wave" }).palette
      opts.highlights = {
        fill = { bg = palette.sumiInk0 },
        background = { fg = palette.fujiGray, bg = palette.sumiInk1 },
        buffer_visible = { fg = palette.oldWhite, bg = palette.sumiInk1 },
        buffer_selected = {
          fg = palette.fujiWhite,
          bg = palette.sumiInk3,
          bold = true,
          italic = false,
        },
        indicator_selected = { fg = palette.carpYellow, bg = palette.sumiInk3 },
        close_button = { fg = palette.fujiGray, bg = palette.sumiInk1 },
        close_button_visible = { fg = palette.oldWhite, bg = palette.sumiInk1 },
        close_button_selected = { fg = palette.peachRed, bg = palette.sumiInk3 },
        modified = { fg = palette.autumnYellow, bg = palette.sumiInk1 },
        modified_visible = { fg = palette.autumnYellow, bg = palette.sumiInk1 },
        modified_selected = { fg = palette.carpYellow, bg = palette.sumiInk3 },
        separator = { fg = palette.sumiInk0, bg = palette.sumiInk1 },
        separator_visible = { fg = palette.sumiInk0, bg = palette.sumiInk1 },
        separator_selected = { fg = palette.sumiInk0, bg = palette.sumiInk3 },
        tab = { fg = palette.fujiGray, bg = palette.sumiInk1 },
        tab_selected = { fg = palette.carpYellow, bg = palette.sumiInk3, bold = true },
        tab_separator = { fg = palette.sumiInk0, bg = palette.sumiInk1 },
        tab_separator_selected = { fg = palette.sumiInk0, bg = palette.sumiInk3 },
        offset_separator = { fg = palette.sumiInk6, bg = palette.sumiInk0 },
      }
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "rebelot/kanagawa.nvim" },
    opts = function(_, opts)
      local kanagawa = require("kanagawa.colors").setup({ theme = "wave" }).theme
      local lualine_theme = vim.deepcopy(require("lualine.themes.kanagawa"))
      -- Keep the mode accents, but use the editor background for the rest of
      -- the bar instead of Kanagawa's opaque bg_p1 strip.
      local default_b = vim.deepcopy(lualine_theme.normal.b)
      local default_c = vim.deepcopy(lualine_theme.normal.c)
      for _, mode in pairs(lualine_theme) do
        mode.b = mode.b or vim.deepcopy(default_b)
        mode.c = mode.c or vim.deepcopy(default_c)
        for _, section in ipairs({ "b", "c" }) do
          mode[section].bg = kanagawa.ui.bg
        end
      end

      local mode_names = {
        NORMAL = "普通",
        INSERT = "插入",
        VISUAL = "可视",
        ["V-LINE"] = "可视行",
        ["V-BLOCK"] = "可视块",
        SELECT = "选择",
        ["S-LINE"] = "选择行",
        ["S-BLOCK"] = "选择块",
        REPLACE = "替换",
        ["V-REPLACE"] = "虚拟替换",
        COMMAND = "命令",
        EX = "Ex 命令",
        MORE = "更多",
        CONFIRM = "确认",
        SHELL = "终端",
        TERMINAL = "终端",
        ["O-PENDING"] = "待操作",
      }

      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        theme = lualine_theme,
        component_separators = { left = "│", right = "│" },
        section_separators = { left = "", right = "" },
      })
      opts.sections = opts.sections or {}
      opts.sections.lualine_a = {
        {
          "mode",
          fmt = function(mode)
            return mode_names[mode] or mode
          end,
        },
      }
    end,
  },
}
