-- Автодополнение (FIM) и чат к локальному инференсу (R8.4, AI_SUBSYSTEM.md §3.2).
-- Адрес сервиса и роль→модель — из machine.d/ai-env (AI-CMP-4), не константы
-- здесь (AI-ROLE-2, DOT-1/DOT-6): модель выбирает Nix по VRAM хоста, dotfiles
-- только читают переменную. AI-CMP-1: FIM идёт напрямую к inference-service,
-- без gateway (он появится в R8.5) — то же верно для чата, пока нет облачного
-- fallback.
local inference_url = os.getenv("AI_INFERENCE_URL") or "http://127.0.0.1:11434"
local fast_model = os.getenv("AI_MODEL_LOCAL_FAST")
local chat_model = os.getenv("AI_MODEL_LOCAL_CHAT")
local has_chat = chat_model ~= nil and chat_model ~= ""

return {
  {
    "milanglacier/minuet-ai.nvim",
    opts = {
      -- AI-CMP-3: полная тишина при недоступном сервисе — не блокирует ввод
      -- и не всплывает ошибками поверх редактора.
      notify = false,
      provider = "openai_fim_compatible",
      -- Профиль языков — ARCHITECTURE.md A.5 (Python/C/C++/Rust/SQL,
      -- вспомогательно Nix/Lua/Bash).
      virtualtext = {
        auto_trigger_ft = { "python", "rust", "c", "cpp", "sql", "nix", "lua", "sh" },
        -- По умолчанию в minuet-ai.nvim клавиши не заданы (upstream README
        -- предлагает именно этот набор) — без них подсказку нечем принять.
        keymap = {
          accept = "<A-a>",
          next = "<A-]>",
          prev = "<A-[>",
          dismiss = "<A-e>",
        },
      },
      provider_options = {
        openai_fim_compatible = {
          name = "Ollama",
          -- Ollama не проверяет ключ — плейсхолдер на существующую
          -- переменную окружения, не секрет (как в upstream README).
          api_key = "TERM",
          end_point = inference_url .. "/v1/completions",
          model = fast_model,
        },
      },
    },
  },
  {
    "olimorris/codecompanion.nvim",
    -- Зависимости — по README проекта (upstream требует оба явно).
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
    keys = {
      {
        "<leader>aa",
        has_chat and "<cmd>CodeCompanionActions<cr>" or function()
          vim.notify("AI chat: local-chat не определена на этом хосте (VRAM-класс) — появится после R8.5", vim.log.levels.WARN, { title = "CodeCompanion" })
        end,
        desc = "AI: actions palette",
      },
      {
        "<leader>ac",
        has_chat and "<cmd>CodeCompanionChat Toggle<cr>" or function()
          vim.notify("AI chat: local-chat не определена на этом хосте (VRAM-класс) — появится после R8.5", vim.log.levels.WARN, { title = "CodeCompanion" })
        end,
        desc = "AI: chat",
      },
      {
        "<leader>ai",
        has_chat and "<cmd>CodeCompanion<cr>" or function()
          vim.notify("AI chat: local-chat не определена на этом хосте (VRAM-класс) — появится после R8.5", vim.log.levels.WARN, { title = "CodeCompanion" })
        end,
        mode = { "n", "v" },
        desc = "AI: inline prompt",
      },
    },
    -- has_chat == false: клавиши выше не доходят до плагина вовсе (guard в
    -- keys). upstream-умолчание codecompanion для interactions.chat.adapter —
    -- "copilot" (config.lua), не "нет адаптера"; без guard'а в keys раздел
    -- :CodeCompanionChat/Actions/inline давал бы "Copilot Adapter: No token
    -- found" (ПРОВЕРЕНО живьём, R8.4) — не трогаем opts в этой ветке, им
    -- просто не дают выполниться.
    opts = has_chat
        and {
          interactions = {
            chat = { adapter = "ollama" },
            inline = { adapter = "ollama" },
          },
          adapters = {
            http = {
              ollama = function()
                return require("codecompanion.adapters").extend("ollama", {
                  env = { url = inference_url },
                  schema = { model = { default = chat_model } },
                })
              end,
            },
          },
        }
      or {},
  },
}
