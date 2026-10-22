-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("octo").setup({
  github_hostname = "github.je-labs.com",
})

vim.cmd.colorscheme("catppuccin-mocha")
