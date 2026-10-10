local M = {}

local function read_binary(path)
  local uv = vim.uv or vim.loop
  local fd, open_error = uv.fs_open(path, "r", 438)
  if not fd then
    return nil, open_error
  end

  local stat, stat_error = uv.fs_fstat(fd)
  if not stat then
    uv.fs_close(fd)
    return nil, stat_error
  end

  local data, read_error = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  return data, read_error
end

local function generate_png(path)
  local config = require("codesnap.config").get_config()
  -- CodeSnap v2.0.5 appends its concrete .so path to package.cpath. Restore
  -- cpath after loading so later native modules (for example blink.cmp) do
  -- not accidentally try to load the CodeSnap generator.
  local original_cpath = package.cpath
  local loaded, generator = pcall(function()
    return require("codesnap.module").load_generator()
  end)
  -- Keep an already-clean search path clean even if an older startup left a
  -- CodeSnap entry behind.
  local clean_cpath = {}
  for entry in original_cpath:gmatch("[^;]+") do
    if not entry:find("codesnap.nvim", 1, true) then
      table.insert(clean_cpath, entry)
    end
  end
  package.cpath = table.concat(clean_cpath, ";")
  if not loaded then
    error(generator, 0)
  end
  generator.save(path, config)
end

function M.copy()
  -- CodeSnap v2's built-in Rust clipboard backend fails on this Wayland
  -- session. Generate a PNG with CodeSnap, then let wl-copy own the image.
  if vim.fn.has("linux") == 0 or not vim.env.WAYLAND_DISPLAY or vim.fn.executable("wl-copy") ~= 1 then
    require("codesnap").copy()
    return
  end

  local uv = vim.uv or vim.loop
  local temporary_png = vim.fn.tempname() .. ".png"
  local generated, generate_error = pcall(generate_png, temporary_png)
  if not generated then
    pcall(uv.fs_unlink, temporary_png)
    vim.notify("代码截图生成失败：" .. tostring(generate_error), vim.log.levels.ERROR, {
      title = "CodeSnap",
    })
    return
  end

  local png, read_error = read_binary(temporary_png)
  pcall(uv.fs_unlink, temporary_png)
  if not png then
    vim.notify("无法读取临时截图：" .. tostring(read_error), vim.log.levels.ERROR, { title = "CodeSnap" })
    return
  end

  -- A detached job returns control to Neovim immediately while wl-copy keeps
  -- serving the Wayland clipboard, even after Neovim exits.
  local stderr = {}
  local job = vim.fn.jobstart({ "wl-copy", "--type", "image/png" }, {
    detach = true,
    on_stderr = function(_, data)
      for _, line in ipairs(data or {}) do
        if line ~= "" then
          table.insert(stderr, line)
        end
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.schedule(function()
          vim.notify("写入 Wayland 剪贴板失败：" .. table.concat(stderr, "\n"), vim.log.levels.ERROR, {
            title = "CodeSnap",
          })
        end)
      end
    end,
  })
  if job <= 0 then
    vim.notify("无法启动 wl-copy，错误码：" .. job, vim.log.levels.ERROR, {
      title = "CodeSnap",
    })
    return
  end
  vim.fn.chansend(job, png)
  vim.fn.chanclose(job, "stdin")

  vim.cmd("delmarks <>")
  vim.notify("代码截图已复制到剪贴板", vim.log.levels.INFO, { title = "CodeSnap" })
end

return M
