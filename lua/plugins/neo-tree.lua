return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true,         -- Always show hidden files
        hide_dotfiles = false,  -- Show dotfiles like .env, .gitignore
        hide_gitignored = false, -- Show files ignored by git
      },
    },
  },
}
