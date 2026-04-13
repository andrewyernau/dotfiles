require("pckr").add({
  -- Dependencies
  "nvim-lua/plenary.nvim",

  -- Theme
  { "catppuccin/nvim", as = "catppuccin" },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    requires = {
      "mrcjkb/rustaceanvim",
    },
    config = function()
      require("config.lsp")
    end,
  },


  -- Completion
  {
    "hrsh7th/nvim-cmp",
    requires = {
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
    },
    config = function()
      require("config.cmp")
    end,
  },

  -- Treesitter
  { "nvim-treesitter/nvim-treesitter",
    branch = "master",
    run = ":TSUpdate",
    config = function()
      require("config.treesitter")
    end,
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    requires = { "nvim-lua/plenary.nvim" }
  },

  -- Git
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup()
    end,
  },

  -- Debug
  {
    "mfussenegger/nvim-dap",
    requires = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      require("config.dap")
    end,
  },
})
