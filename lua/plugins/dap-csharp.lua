return {
  -- Ensure netcoredbg is installed via Mason
  {
    "jay-babu/mason-nvim-dap.nvim",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "netcoredbg" })
    end,
  },

  {
    "mfussenegger/nvim-dap",
    optional = true,
    config = function()
      local dap = require("dap")

      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "DapStoppedLine", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticError", linehl = "", numhl = "" })

      dap.adapters.coreclr = {
        type = "executable",
        command = vim.fn.exepath("netcoredbg"),
        args = { "--interpreter=vscode" },
      }

      -- Finds a built dll under bin/Debug, trying common TFMs
      local function find_dll(project_dir, project_name)
        for _, tfm in ipairs({ "net8.0", "net9.0", "net7.0" }) do
          local dll = project_dir .. "/bin/Debug/" .. tfm .. "/" .. project_name .. ".dll"
          if vim.fn.filereadable(dll) == 1 then
            return dll
          end
        end
        return vim.fn.input("Path to dll: ", project_dir .. "/bin/Debug/", "file")
      end

      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "Launch (nearest project)",
          request = "launch",
          program = function()
            local csproj = vim.fn.glob(vim.fn.getcwd() .. "/**/*.csproj", false, true)[1]
            if not csproj then
              return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/", "file")
            end
            return find_dll(
              vim.fn.fnamemodify(csproj, ":h"),
              vim.fn.fnamemodify(csproj, ":t:r")
            )
          end,
        },
        {
          -- Handy for Reqnroll/BDD: set breakpoints in step defs, run all scenarios
          type = "coreclr",
          name = "Debug FinanceCore.Tests",
          request = "launch",
          program = function()
            local root = vim.fn.finddir(".git", vim.fn.expand("%:p:h") .. ";")
            root = vim.fn.fnamemodify(root, ":h")
            return find_dll(root .. "/FinanceCore.Tests", "FinanceCore.Tests")
          end,
        },
        {
          -- Run only scenarios matching a filter (dotnet test --filter style)
          type = "coreclr",
          name = "Debug FinanceCore.Tests (with filter)",
          request = "launch",
          program = function()
            local root = vim.fn.finddir(".git", vim.fn.expand("%:p:h") .. ";")
            root = vim.fn.fnamemodify(root, ":h")
            return find_dll(root .. "/FinanceCore.Tests", "FinanceCore.Tests")
          end,
          args = function()
            local filter = vim.fn.input("Test filter (e.g. Category=tenant-ie): ")
            if filter == "" then return {} end
            return { "--filter", filter }
          end,
        },
        {
          type = "coreclr",
          name = "Attach to process",
          request = "attach",
          processId = require("dap.utils").pick_process,
        },
      }
    end,
  },
}
