return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
    event_handlers = {
      {
        event = "neo_tree_window_before_open",
        handler = function()
          require("center-code").before_neotree_open()
        end,
      },
      {
        event = "neo_tree_window_after_open",
        handler = function()
          require("center-code").after_neotree_open()
        end,
      },
      {
        event = "neo_tree_window_before_close",
        handler = function()
          require("center-code").before_neotree_close()
        end,
      },
      {
        event = "neo_tree_window_after_close",
        handler = function()
          require("center-code").after_neotree_close()
        end,
      },
    },
  },
}
