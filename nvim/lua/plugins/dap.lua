-- Отладка (R6.12, DEV-5): адаптеры — ТОЛЬКО уже установленные Nix-пакеты
-- lsp-global.nix, без Mason (DEV-4/DEV-5: адаптеры поставляет проектное
-- окружение или lsp-global, не менеджер плагинов редактора).
-- python3Packages.debugpy ставит на PATH готовый бинарник `debugpy-adapter`
-- (подтверждено сборкой пакета) — используем его прямо, без `python3 -m
-- debugpy.adapter`. lldb ставит `lldb-dap` (подтверждено) — для C/C++/Rust.
return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")
    dapui.setup()

    dap.adapters.python = {
      type = "executable",
      command = "debugpy-adapter",
    }
    dap.configurations.python = {
      {
        type = "python",
        request = "launch",
        name = "Launch file",
        program = "${file}",
      },
    }

    dap.adapters.lldb = {
      type = "executable",
      command = "lldb-dap",
      name = "lldb",
    }
    local lldb_config = {
      {
        name = "Launch",
        type = "lldb",
        request = "launch",
        program = function()
          return vim.fn.input("Путь к исполняемому файлу: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
      },
    }
    dap.configurations.c = lldb_config
    dap.configurations.cpp = lldb_config
    dap.configurations.rust = lldb_config

    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end

    local map = vim.keymap.set
    map("n", "<leader>db", dap.toggle_breakpoint, { desc = "Переключить breakpoint" })
    map("n", "<leader>dc", dap.continue, { desc = "Отладка: continue" })
    map("n", "<leader>do", dap.step_over, { desc = "Отладка: step over" })
    map("n", "<leader>di", dap.step_into, { desc = "Отладка: step into" })
    map("n", "<leader>dq", dap.terminate, { desc = "Отладка: завершить" })
  end,
}
