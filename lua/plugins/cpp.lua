local toolchain = require("config.cp-toolchain")
local clangd_command = {
  "clangd",
  "--background-index",
  "--clang-tidy",
  "--completion-style=detailed",
  "--function-arg-placeholders",
  "--header-insertion=never",
}
local drivers = {}
for _, language in ipairs({ "c", "cpp" }) do
  local path = vim.fn.exepath(toolchain.compiler(language))
  if path ~= "" then
    table.insert(drivers, vim.fs.normalize(path))
  end
end
if #drivers > 0 then
  table.insert(clangd_command, "--query-driver=" .. table.concat(drivers, ","))
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
      servers = {
        clangd = {
          single_file_support = true,
          -- Keep the editor quiet during contests: clangd reports only real
          -- errors. g++ still prints -Wall/-Wextra/-Wshadow warnings whenever
          -- CompetiTest performs an actual compilation.
          handlers = {
            ["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
              if result and result.diagnostics then
                result.diagnostics = vim.tbl_filter(function(diagnostic)
                  return not diagnostic.severity
                    or diagnostic.severity == vim.lsp.protocol.DiagnosticSeverity.Error
                end, result.diagnostics)
              end
              return vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, config)
            end,
          },
          cmd = clangd_command,
          init_options = {
            clangdFileStatus = true,
            completeUnimported = true,
            usePlaceholders = true,
            fallbackFlags = {
              "-std=gnu++20",
              "-Wall",
              "-Wextra",
              "-Wshadow",
            },
          },
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "clangd",
        "clang-format",
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        c = { "clang_format" },
        cpp = { "clang_format" },
      },
      formatters = {
        clang_format = {
          prepend_args = {
            "--style={BasedOnStyle: Google, IndentWidth: 4, ColumnLimit: 100, SortIncludes: Never, AllowShortFunctionsOnASingleLine: Empty}",
          },
        },
      },
    },
  },
}
