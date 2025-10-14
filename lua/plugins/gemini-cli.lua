return {
  "jonroosevelt/gemini-cli.nvim",
  config = function()
    require("gemini").setup({
      split_direction = "horizontal", -- optional: "vertical" (default) or "horizontal"
    })
  end,
}