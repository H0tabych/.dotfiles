-- Отладка (R6.12/R6.15, DEV-5): адаптеры — ТОЛЬКО уже установленные Nix-пакеты
-- lsp-global.nix, без Mason (DEV-4/DEV-5: адаптеры поставляет проектное
-- окружение или lsp-global, не менеджер плагинов редактора).
-- python3Packages.debugpy ставит на PATH готовый бинарник `debugpy-adapter`
-- (подтверждено сборкой пакета) — используем его прямо, без `python3 -m
-- debugpy.adapter`. lldb ставит `lldb-dap` (подтверждено) — для C/C++/Rust.
-- R6.15: запуск с аргументами/конкретным модулем, в общем виде — не привязано
-- к открытому файлу (program больше не `${file}`), спрашивает при каждом
-- запуске; поле `module` — проверено живьём (debugpy/adapter/clients.py:
-- "program", "module" и "code" взаимоисключающие ключи launch-запроса DAP).
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

    -- Отмена (<C-c>) на любом из input() не прерывает весь launch молча:
    -- vim.fn.input возвращает "" — тогда используем default как есть.
    local function ask(prompt, default, completion)
      local ok, result = pcall(vim.fn.input, { prompt = prompt, default = default or "", completion = completion })
      if not ok or result == "" then
        return default or ""
      end
      return result
    end

    local function ask_args()
      local raw = ask("Аргументы: ")
      if raw == "" then
        return {}
      end
      return vim.split(raw, "%s+")
    end

    local function ask_cwd()
      return ask("Рабочая директория: ", vim.fn.getcwd(), "dir")
    end

    dap.adapters.python = {
      type = "executable",
      command = "debugpy-adapter",
    }
    dap.configurations.python = {
      {
        type = "python",
        request = "launch",
        name = "Launch file",
        program = function()
          return ask("Файл: ", vim.fn.expand("%:p"), "file")
        end,
        args = ask_args,
        cwd = ask_cwd,
      },
      {
        type = "python",
        request = "launch",
        name = "Launch module (-m ...)",
        module = function()
          return ask("Модуль (как в python -m ...): ")
        end,
        args = ask_args,
        cwd = ask_cwd,
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
          return ask("Исполняемый файл: ", vim.fn.getcwd() .. "/", "file")
        end,
        args = ask_args,
        cwd = ask_cwd,
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
    map("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: toggle breakpoint" })
    map("n", "<leader>dB", function()
      dap.set_breakpoint(ask("Условие breakpoint: "))
    end, { desc = "Debug: conditional breakpoint" })
    map("n", "<leader>dc", dap.continue, { desc = "Debug: continue / start" })
    map("n", "<leader>do", dap.step_over, { desc = "Debug: step over" })
    map("n", "<leader>di", dap.step_into, { desc = "Debug: step into" })
    map("n", "<leader>dO", dap.step_out, { desc = "Debug: step out" })
    map("n", "<leader>dq", dap.terminate, { desc = "Debug: terminate" })
    map("n", "<leader>dr", dap.restart, { desc = "Debug: restart" })
    map("n", "<leader>du", dapui.toggle, { desc = "Debug: toggle UI" })
  end,
}
