return {
  "mason-org/mason.nvim",
  opts = function(_, opts)
    opts.registries = opts.registries or {}
    table.insert(opts.registries, "github:Crashdummyy/mason-registry")
  end,
}
