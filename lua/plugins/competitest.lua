return {
  {
    "xeluxee/competitest.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "CompetiTest",
    keys = {
      { "<leader>jr", "<cmd>CompetiTest run<cr>", desc = "编译并运行全部样例" },
      { "<leader>jR", "<cmd>CompetiTest run_no_compile<cr>", desc = "不重新编译直接运行" },
      { "<leader>ja", "<cmd>CompetiTest add_testcase<cr>", desc = "添加样例" },
      { "<leader>je", "<cmd>CompetiTest edit_testcase<cr>", desc = "编辑样例" },
      { "<leader>jd", "<cmd>CompetiTest delete_testcase<cr>", desc = "删除样例" },
      { "<leader>js", "<cmd>CompetiTest show_ui<cr>", desc = "显示上次评测结果" },
      {
        "<leader>jn",
        function()
          require("config.cp-workspace").create_source_file()
        end,
        desc = "新建题目文件",
      },
      { "<leader>jp", "<cmd>CompetiTest receive problem<cr>", desc = "接收单道题目" },
      { "<leader>jc", "<cmd>CompetiTest receive contest<cr>", desc = "接收整场比赛" },
    },
    opts = function()
      local toolchain = require("config.cp-toolchain")
      return {
        floating_border = "rounded",
        runner_ui = {
          interface = "popup",
          selector_show_nu = false,
          selector_show_rnu = false,
          show_nu = true,
          show_rnu = false,
          viewer = {
            width = 0.7,
            height = 0.7,
            show_nu = true,
            show_rnu = false,
            open_when_compilation_fails = true,
          },
        },
        popup_ui = {
          total_width = 0.9,
          total_height = 0.85,
          layout = {
            { 4, "tc" },
            { 5, { { 1, "so" }, { 1, "si" } } },
            { 5, { { 1, "eo" }, { 1, "se" } } },
          },
        },
        save_current_file = true,
        save_all_files = false,
        compile_directory = ".",
        compile_command = {
          c = {
            exec = toolchain.compiler("c"),
            args = { "-std=gnu17", "-O2", "-pipe", "-Wall", "-Wextra", "$(FNAME)", "-o", toolchain.output_name() },
          },
          cpp = {
            exec = toolchain.compiler("cpp"),
            args = {
              "-std=gnu++20",
              "-O2",
              "-pipe",
              "-Wall",
              "-Wextra",
              "-Wshadow",
              "$(FNAME)",
              "-o",
              toolchain.output_name(),
            },
          },
        },
        running_directory = ".",
        run_command = {
          c = { exec = toolchain.run_path() },
          cpp = { exec = toolchain.run_path() },
        },
        multiple_testing = -1,
        maximum_time = 10000,
        output_compare_method = "squish",
        view_output_diff = false,
        -- Match the old Sublime/FastOlympicCoding contest layout: all source
        -- files are placed in the contest directory and all samples share one
        -- TESTCASE directory. Prefix sample names with the source file stem so
        -- samples from A.cpp and B.cpp never overwrite each other.
        testcases_directory = "TESTCASE",
        testcases_use_single_file = false,
        testcases_auto_detect_storage = true,
        testcases_single_file_format = "$(FNOEXT).testcases",
        testcases_input_file_format = "$(FNOEXT)_input$(TCNUM).txt",
        testcases_output_file_format = "$(FNOEXT)_output$(TCNUM).txt",
        companion_port = 27121,
        start_receiving_persistently_on_setup = false,
        template_file = vim.fn.stdpath("config") .. "/templates/main.cpp",
        evaluate_template_modifiers = true,
        received_files_extension = "cpp",
        received_problems_path = "$(CWD)/$(PROBLEM).$(FEXT)",
        received_problems_prompt_path = true,
        received_contests_directory = "$(CWD)/$(CONTEST)",
        received_contests_problems_path = "$(PROBLEM).$(FEXT)",
        received_contests_prompt_directory = true,
        received_contests_prompt_extension = false,
        open_received_problems = true,
        open_received_contests = true,
        replace_received_testcases = false,
      }
    end,
  },
}
