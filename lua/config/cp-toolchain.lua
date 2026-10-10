local M = {}

function M.compiler(language)
  local name = language == "c" and "gcc" or "g++"
  local override = vim.g[language == "c" and "cp_cc" or "cp_cxx"]
  if override and override ~= "" then
    local path = vim.fn.exepath(override)
    return path ~= "" and path or override
  end

  -- On macOS, use GNU GCC 15 rather than the unversioned Apple Clang aliases.
  if vim.fn.has("macunix") == 1 then
    name = name .. "-15"
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
