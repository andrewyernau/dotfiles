require("pckr").add({
  "nvim-lua/plenary.nvim",

  { "nvim-telescope/telescope.nvim" },

  { "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" },

  { "neovim/nvim-lspconfig" },

  { "windwp/nvim-autopairs" },

  { "lewis6991/gitsigns.nvim" },

  { "catppuccin/nvim", as = "catppuccin" },
})
