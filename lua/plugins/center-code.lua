return {
  {
    dir = vim.fn.stdpath("config") .. "/lua",
    name = "center-code",
    lazy = false,
    config = function()
      require("center-code").setup({
        width = 120,
      })
    end,
  },
}
