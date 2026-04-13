return {
  "mason-org/mason.nvim",
  opts = function(_, opts)
    opts.registries = {
      "github:mason-org/mason-registry",
      "github:Crashdummyy/mason-registry",
    }
  end,
}
