-- ~/.config/nvim/init.lua (replaces ~/.vimrc + vim-plug)

vim.g.mapleader = " "

-- Options (carried over from .vimrc, plus a few modern defaults)
vim.o.mouse = "a"
vim.o.number = true
vim.o.clipboard = "unnamedplus"
vim.o.termguicolors = true
vim.o.signcolumn = "yes"
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.scrolloff = 5
vim.o.updatetime = 250
vim.o.winborder = "single"

-- Clipboard mappings from the old .vimrc
vim.keymap.set("v", "<C-c>", '"+y')
vim.keymap.set("v", "<C-x>", '"+d')
vim.keymap.set("v", "<C-v>", '"_d"+P')
vim.keymap.set("i", "<C-v>", "<C-r><C-o>+")

-- Plugins (built-in package manager; update with :lua vim.pack.update())
vim.pack.add({
  "https://github.com/nvim-mini/mini.nvim",
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/mason-org/mason-lspconfig.nvim",
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.*") },
  "https://github.com/lewis6991/gitsigns.nvim",
})

-- Colors from wallust (replaces wal.vim); falls back to the default scheme.
local ok, palette = pcall(dofile, vim.fn.expand("~/.cache/wallust/colors-nvim.lua"))
if ok then
  require("mini.base16").setup({ palette = palette })
end

require("mini.icons").setup()
require("mini.statusline").setup()  -- replaces vim-airline
require("mini.files").setup()       -- replaces NERDTree
require("mini.pick").setup()
require("mini.pairs").setup()
require("gitsigns").setup()

vim.keymap.set("n", "<F2>", function()
  if not require("mini.files").close() then
    require("mini.files").open(vim.api.nvim_buf_get_name(0))
  end
end, { desc = "Toggle file browser" })
vim.keymap.set("n", "<leader>f", "<cmd>Pick files<cr>", { desc = "Find files" })
vim.keymap.set("n", "<leader>g", "<cmd>Pick grep_live<cr>", { desc = "Live grep" })
vim.keymap.set("n", "<leader>b", "<cmd>Pick buffers<cr>", { desc = "Buffers" })
vim.keymap.set("n", "<leader>h", "<cmd>Pick help<cr>", { desc = "Help" })

-- Treesitter: install parsers on demand, highlight when one is available.
local parsers = { "bash", "c", "css", "json", "lua", "markdown", "python", "toml", "vim", "vimdoc", "yaml" }
require("nvim-treesitter").install(parsers)
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    if pcall(vim.treesitter.start, args.buf) then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- LSP: install servers with :Mason; installed servers are enabled automatically.
require("mason").setup()
require("mason-lspconfig").setup({ ensure_installed = { "lua_ls" } })
vim.lsp.config("lua_ls", {
  settings = { Lua = { workspace = { library = vim.api.nvim_get_runtime_file("", true) } } },
})
vim.diagnostic.config({ virtual_text = true })

require("blink.cmp").setup({
  keymap = { preset = "default" },
  signature = { enabled = true },
})
