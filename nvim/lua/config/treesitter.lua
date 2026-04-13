require("nvim-treesitter.configs").setup({
  ensure_installed = {
    "rust",
    "lua",
    "vim",
    "bash",
    "markdown",
    "toml",
  },

  highlight = {
    enable = true,
  },

  indent = {
    enable = true,
  },
})
