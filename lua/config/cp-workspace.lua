local M = {}

local function xcpc_root()
  -- This override also makes the module easy to test without touching real data.
  return vim.g.cp_workspace_root or vim.fn.expand("~/XCPC")
end

local function ensure_directory(path)
  if vim.fn.isdirectory(path) == 1 then
    return true
  end
  return vim.fn.mkdir(path, "p") == 1 or vim.fn.isdirectory(path) == 1
end

local function recent_directories_file()
  return vim.g.cp_recent_directories_file
    or vim.fs.joinpath(vim.fn.stdpath("state"), "cp-recent-directories.json")
end

local function normalize_directory(path)
  local normalized = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
  return (vim.uv or vim.loop).fs_realpath(normalized) or normalized
end

local function load_saved_directories()
  local path = recent_directories_file()
  if vim.fn.filereadable(path) ~= 1 then
    return {}
  end

  local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
  if not ok or type(decoded) ~= "table" then
    return {}
  end

  local directories = {}
  for _, directory in ipairs(decoded) do
    if type(directory) == "string" and vim.fn.isdirectory(directory) == 1 then
      table.insert(directories, normalize_directory(directory))
    end
  end
  return directories
end

local function remember_directory(path)
  path = normalize_directory(path)
  local directories = { path }
  for _, directory in ipairs(load_saved_directories()) do
    if directory ~= path and #directories < 30 then
      table.insert(directories, directory)
    end
  end

  local state_file = recent_directories_file()
  ensure_directory(vim.fn.fnamemodify(state_file, ":h"))
  pcall(vim.fn.writefile, { vim.json.encode(directories) }, state_file)
end

local function enter_directory(path, label)
  path = normalize_directory(path)
  local ok, err = pcall(vim.api.nvim_set_current_dir, path)
  if not ok then
    vim.notify("无法进入目录：" .. tostring(err), vim.log.levels.ERROR, { title = "算法竞赛" })
    return
  end

  remember_directory(path)
  vim.notify("已进入" .. label .. "\n" .. path, vim.log.levels.INFO, { title = "算法竞赛" })
  if _G.Snacks then
    Snacks.explorer({ cwd = path })
  end
end

local function open_workspace(path, label)
  if not ensure_directory(path) then
    vim.notify("无法创建目录：" .. path, vim.log.levels.ERROR, { title = "算法竞赛" })
    return
  end

  local testcase_path = vim.fs.joinpath(path, "TESTCASE")
  if not ensure_directory(testcase_path) then
    vim.notify("无法创建样例目录：" .. testcase_path, vim.log.levels.ERROR, { title = "算法竞赛" })
    return
  end

  enter_directory(path, label)
end

local function valid_directory_name(name)
  return name ~= ""
    and name ~= "."
    and name ~= ".."
    and not name:find("/", 1, true)
    and not name:find("\\", 1, true)
    and not name:find("\0", 1, true)
end

local function cpp_template_file()
  return vim.g.cp_cpp_template
    or vim.fs.joinpath(vim.fn.stdpath("config"), "templates", "main.cpp")
end

local function expand_manual_template(lines, filename)
  local problem = vim.fn.fnamemodify(filename, ":r")
  local group = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  local replacements = {
    { "%$%(PROBLEM%)", problem },
    { "%$%(GROUP%)", group },
    { "%$%(URL%)", "" },
    -- Also support the placeholders used by the old Sublime template.
    { "%$name%$", problem },
    { "%$group%$", group },
    { "%$url%$", "" },
  }

  for index, line in ipairs(lines) do
    for _, replacement in ipairs(replacements) do
      line = line:gsub(replacement[1], function()
        return replacement[2]
      end)
    end
    lines[index] = line
  end
  return lines
end

function M.create_source_file()
  vim.ui.input({
    prompt = "源码文件名：",
    default = "A.cpp",
  }, function(input)
    if input == nil then
      return
    end

    local filename = vim.trim(input)
    if not valid_directory_name(filename) then
      vim.notify("文件名不能为空、`.`、`..`，也不能包含路径分隔符。", vim.log.levels.WARN, {
        title = "新建题目",
      })
      return
    end
    if vim.fn.fnamemodify(filename, ":e") == "" then
      filename = filename .. ".cpp"
    end

    local path = vim.fs.joinpath(vim.fn.getcwd(), filename)
    if vim.fn.filereadable(path) == 1 then
      vim.cmd.edit(vim.fn.fnameescape(path))
      vim.notify("文件已存在，已直接打开且未覆盖。", vim.log.levels.INFO, { title = "新建题目" })
      return
    end

    local choices = {
      { label = "套用 C++ 模板", use_template = true },
      { label = "创建空文件", use_template = false },
    }
    vim.ui.select(choices, {
      prompt = "是否套用模板？",
      format_item = function(item)
        return item.label
      end,
    }, function(choice)
      if not choice then
        return
      end

      local lines = {}
      if choice.use_template then
        local template = cpp_template_file()
        if vim.fn.filereadable(template) ~= 1 then
          vim.notify("找不到 C++ 模板：" .. template, vim.log.levels.ERROR, { title = "新建题目" })
          return
        end
        lines = expand_manual_template(vim.fn.readfile(template), filename)
      end

      local write_result = vim.fn.writefile(lines, path)
      if write_result ~= 0 then
        vim.notify("无法创建文件：" .. path, vim.log.levels.ERROR, { title = "新建题目" })
        return
      end

      vim.cmd.edit(vim.fn.fnameescape(path))
      vim.notify(
        choice.use_template and "已使用模板创建 " .. filename or "已创建空文件 " .. filename,
        vim.log.levels.INFO,
        { title = "新建题目" }
      )
    end)
  end)
end

function M.start_contest()
  vim.ui.input({
    prompt = "比赛文件夹名称：",
    default = os.date("%Y-%m-%d "),
  }, function(input)
    if input == nil then
      return
    end

    local name = vim.trim(input)
    if not valid_directory_name(name) then
      vim.notify("文件夹名不能为空、`.`、`..`，也不能包含路径分隔符。", vim.log.levels.WARN, {
        title = "开始比赛",
      })
      return
    end

    local path = vim.fs.joinpath(xcpc_root(), "contest", name)
    local existed = vim.fn.isdirectory(path) == 1
    open_workspace(path, "比赛：" .. name)
    if existed then
      vim.notify("该比赛目录已存在，已直接进入。", vim.log.levels.INFO, { title = "开始比赛" })
    end
  end)
end

local known_platforms = {
  { directory = "luogu", label = "洛谷" },
  { directory = "codeforces", label = "Codeforces" },
  { directory = "atcoder", label = "AtCoder" },
  { directory = "pta", label = "PTA" },
  { directory = "yawn", label = "每日一题（Yawn）" },
}

local function practice_platforms(root)
  local platforms = {
    { directory = "", label = "综合练习" },
  }
  local seen = { TESTCASE = true }

  for _, platform in ipairs(known_platforms) do
    seen[platform.directory] = true
    table.insert(platforms, platform)
  end

  if vim.fn.isdirectory(root) == 1 then
    local extras = {}
    for directory, kind in vim.fs.dir(root) do
      if kind == "directory" and not seen[directory] and directory:sub(1, 1) ~= "." then
        table.insert(extras, { directory = directory, label = directory })
      end
    end
    table.sort(extras, function(a, b)
      return a.label < b.label
    end)
    vim.list_extend(platforms, extras)
  end

  return platforms
end

function M.start_practice()
  local root = vim.fs.joinpath(xcpc_root(), "practice")
  if not ensure_directory(root) then
    vim.notify("无法创建练习根目录：" .. root, vim.log.levels.ERROR, { title = "开始练习" })
    return
  end

  vim.ui.select(practice_platforms(root), {
    prompt = "选择练习平台：",
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    if not item then
      return
    end
    local path = item.directory == "" and root or vim.fs.joinpath(root, item.directory)
    open_workspace(path, "练习：" .. item.label)
  end)
end

function M.open_recent_directory()
  local items = {}
  local seen = {}

  local function add(path)
    if type(path) ~= "string" or path == "" or vim.fn.isdirectory(path) ~= 1 then
      return
    end
    path = normalize_directory(path)
    if seen[path] then
      return
    end
    seen[path] = true
    table.insert(items, {
      path = path,
      label = vim.fn.fnamemodify(path, ":~"),
    })
  end

  for _, directory in ipairs(load_saved_directories()) do
    add(directory)
  end
  local testcase_directories = {
    [".cph"] = true,
    CPHTEMP = true,
    TEMP = true,
    TESTCASE = true,
    testcases = true,
  }
  for _, file in ipairs(vim.v.oldfiles or {}) do
    local directory = vim.fn.fnamemodify(file, ":p:h")
    if testcase_directories[vim.fn.fnamemodify(directory, ":t")] then
      directory = vim.fn.fnamemodify(directory, ":h")
    end
    add(directory)
  end

  if #items == 0 then
    vim.notify("还没有可用的最近目录。", vim.log.levels.INFO, { title = "最近打开目录" })
    return
  end

  vim.ui.select(items, {
    prompt = "选择最近打开的目录：",
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    if item then
      enter_directory(item.path, "目录：" .. item.label)
    end
  end)
end

return M
