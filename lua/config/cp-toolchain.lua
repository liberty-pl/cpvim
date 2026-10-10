local M = {}

function M.compiler(language)
  local name = language == "c" and "gcc" or "g++"
  local override = vim.g[language == "c" and "cp_cc" or "cp_cxx"]
  if override and override ~= "" then
    local path = vim.fn.exepath(override)
    return path ~= "" and path or override
  end

  -- On macOS, unversioned gcc/g++ usually invoke Apple Clang. Prefer the
  -- versioned GNU compiler so the contest template can use bits/stdc++.h.
  if vim.fn.has("macunix") == 1 then
    local newest_version, newest_path = 0, nil
    for _, directory in ipairs(vim.split(vim.env.PATH or "", ":", { trimempty = true })) do
      for _, path in ipairs(vim.fn.glob(vim.fs.joinpath(directory, name .. "-[0-9]*"), false, true)) do
        local version = tonumber(vim.fn.fnamemodify(path, ":t"):match("%-(%d+)$"))
        if version and version > newest_version and vim.fn.executable(path) == 1 then
          newest_version, newest_path = version, path
        end
      end
    end
    if newest_path then
      return newest_path
    end
  end

  local path = vim.fn.exepath(name)
  return path ~= "" and path or name
end

function M.output_name()
  return "$(FNOEXT)" .. (vim.fn.has("win32") == 1 and ".exe" or "")
end

function M.run_path()
  return (vim.fn.has("win32") == 1 and ".\\" or "./") .. M.output_name()
end

return M
