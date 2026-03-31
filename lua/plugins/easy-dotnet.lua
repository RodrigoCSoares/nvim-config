return {
  "GustavEikaas/easy-dotnet.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("easy-dotnet").setup({
      lsp = {
        enabled = true, -- Enable builtin roslyn lsp
        roslynator_enabled = true, -- Automatically enable roslynator analyzer
        auto_refresh_codelens = true,
        analyzer_assemblies = {}, -- Any additional roslyn analyzers you might use like SonarAnalyzer.CSharp
        config = {
          settings = {
            ["csharp|code_lens"] = {
              dotnet_enable_references_code_lens = false,
            },
          },
        },
      },
    })
  end,
}
