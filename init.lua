-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- general configs
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.splitright = true
vim.opt.clipboard = "unnamedplus"
vim.opt.tabstop = 2
vim.o.scrolloff = 6
vim.cmd.colorscheme("habamax")
vim.keymap.set("n", "<leader>p", '"_dP')

vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  callback = function()
    vim.cmd("wincmd L") -- Move help window to the right
  end,
})

-- lazy
require("config.lazy")

-- Treesitter
require("nvim-treesitter.configs").setup({ highlight = { enable = true } })

-- Mason
local Mason = require("mason")
Mason.setup()

local function request_ts_tools_sync(...)
  local clients = vim.lsp.get_active_clients({ name = "typescript-tools" })
  local client = clients[1]

  if not client then
    return "No LSP client found", nil
  end

  local result = client.request_sync("workspace/willRenameFiles", ...)

  return result and result.error, result and result.result
end

-- "tree navigation"
require("mini.files").setup()
vim.keymap.set("n", "<leader>om", function()
  local buf_path = vim.api.nvim_buf_get_name(0)
  if not buf_path or buf_path == "" then
    require("mini.files").open()
  else
    local dir = vim.fn.fnamemodify(buf_path, ":p:h")
    require("mini.files").open(dir)
  end
end)
vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("__mini", { clear = true }),
  pattern = "MiniFilesActionRename",
  callback = function(params)
    -- implementation based in typescript-tools rename funcionality
    local from = vim.uri_from_fname(params.data.from)
    local to = vim.uri_from_fname(params.data.to)

    local err, result = request_ts_tools_sync({
      files = {
        {
          oldUri = from,
          newUri = to,
        },
      },
    })

    if err then
      error(err)
    else
      vim.lsp.util.apply_workspace_edit(result or {}, "utf-8")
    end
  end,
})
vim.keymap.set({ "n" }, "<leader>oM", MiniFiles.open)

-- Toggle zen mode
local zenmode = require("zen-mode")
zenmode.setup({
  on_open = function(_)
    vim.cmd("cabbrev <buffer> q let b:quitting = 1 <bar> q")
    vim.cmd("cabbrev <buffer> wq let b:quitting = 1 <bar> wq")
  end,
  on_close = function()
    if vim.b.quitting == 1 then
      vim.b.quitting = 0
      vim.cmd("q")
    end
  end,
})
vim.keymap.set("n", "<leader>tz", zenmode.toggle, { desc = "Toggle zen mode" })

-- lsp
local function setup_format_on_save(client, bufnr)
  if client.server_capabilities.documentFormattingProvider then
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("LspFormatOnSave", { clear = true }),
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.format({ async = false })
      end,
    })
  end
end

local lspconfig = require("lspconfig")

lspconfig.elixirls.setup({
  cmd = { "/path/to/elixir-ls/language_server.sh" }, -- 👈 Update this path!
  on_attach = function(client, bufnr)
    -- Enable LSP format-on-save for Elixir
    if client.server_capabilities.documentFormattingProvider then
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup(
          "LspFormatOnSaveElixir",
          { clear = true }
        ),
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({ async = false })
        end,
      })
    end
  end,
})

lspconfig.lua_ls.setup({
  settings = {
    Lua = {
      runtime = {
        -- for neovim
        version = "LuaJIT",
      },
      diagnostics = {
        -- Recognize the `vim` global (prevents "undefined global vim" errors)
        globals = { "vim" },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      telemetry = {
        enable = false,
      },
    },
  },
})

-- conform
conform = require("conform")
conform.setup({
  formatters_by_ft = {
    lua = { "stylua" },
    javascript = { "eslint" },
    typescript = { "eslint" },
    javascriptreact = { "eslint" },
    typescriptreact = { "eslint" },
  },
  formatters = {
    -- Prettier
    prettier = {
      command = "prettier",
      args = { "--stdin-filepath", "$FILENAME" },
      stdin = true,
      require_cwd = true,
    },

    -- ESLint --fix
    eslint_fix = {
      command = "eslint",
      args = { "--fix", "--stdin", "--stdin-filename", "$FILENAME" },
      stdin = true,
    },

    -- Prettier + ESLint chain
    prettier_eslint_combo = {
      inherit = false,
      command = "",
      condition = function(ctx)
        -- Only run this if NO LSP attached with formatting capability
        local clients = vim.lsp.get_active_clients({ bufnr = ctx.bufnr })
        for _, client in ipairs(clients) do
          if client.server_capabilities.documentFormattingProvider then
            -- LSP can format this file (likely Biome), so skip running Prettier + ESLint
            return false
          end
        end
        return true
      end,
      run = function(ctx)
        conform.format({ bufnr = ctx.bufnr, formatters = { "prettier" } })
        conform.format({ bufnr = ctx.bufnr, formatters = { "eslint_fix" } })
      end,
    },
  },

  format_on_save = {
    lsp_fallback = true,
    timeout_ms = 1000,
  },
})
vim.keymap.set("n", "<leader>bf", conform.format, { desc = "Format buffer" })

-- Telescope
local tlscope_builtin = require("telescope.builtin")
vim.keymap.set(
  "n",
  "<leader><leader>",
  tlscope_builtin.buffers,
  { desc = "Telescope buffers" }
)
vim.keymap.set(
  "n",
  "<leader>sf",
  tlscope_builtin.find_files,
  { desc = "Tele[S]cope [F]iles in workspace" }
)
vim.keymap.set(
  "n",
  "<leader>sg",
  tlscope_builtin.live_grep,
  { desc = "Tele[S]cope live [G]rep" }
)
vim.keymap.set(
  "n",
  "<leader>sh",
  tlscope_builtin.help_tags,
  { desc = "Tele[S]cope [H]elp tags" }
)
vim.keymap.set(
  "n",
  "<leader>sz",
  tlscope_builtin.builtin,
  { desc = "Tele[S]cope list [B]uiltins" }
)
vim.keymap.set(
  "n",
  "<leader>sD",
  tlscope_builtin.diagnostics,
  { desc = "Tele[S]cope [D]iagnostics" }
)
vim.keymap.set(
  "n",
  "<leader>shk",
  tlscope_builtin.keymaps,
  { desc = "Tele[S]cope [H]elp [K]eymaps" }
)
vim.keymap.set("n", "<leader>snc", function()
  tlscope_builtin.find_files({ cwd = vim.fn.stdpath("config") })
end, { desc = "[S]earch [N]eovim [C]onfig" })

require("typescript-tools").setup({
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
  on_attach = function(client, bufnr)
    setup_format_on_save(client, bufnr)
  end,
})

vim.lsp.config("biome", {})
vim.lsp.enable("biome")

vim.lsp.config("eslint", {})
vim.lsp.enable("eslint")

-- other lsp config
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or "n"
      vim.keymap.set(
        mode,
        keys,
        func,
        { buffer = event.buf, desc = "LSP: " .. desc }
      )
    end

    map("<leader>lr", vim.lsp.buf.rename, "[L]sp [R]ename")
    map(
      "<leader>la",
      vim.lsp.buf.code_action,
      "[L]SP Code [A]ction",
      { "n", "x" }
    )
    map("<leader>ld", vim.lsp.buf.declaration, "[L]SP [D]eclaration")
    map("<leader>lmf", function()
      require("typescript-tools.api").rename_file()
    end, "[L]SP [M]ove to [F]ile")

    map(
      "<leader>sd",
      tlscope_builtin.lsp_definitions,
      "Tele[S]cope [D]efinition"
    )
    map(
      "<leader>sr",
      tlscope_builtin.lsp_references,
      "Tele[S]cope [R]eferences"
    )
    map(
      "<leader>si",
      tlscope_builtin.lsp_implementations,
      "Tele[S]cope [I]mplementation"
    )
    map(
      "<leader>ssd",
      tlscope_builtin.lsp_document_symbols,
      "Tele[S]cope [D]ocument [S]ymbols"
    )
    map(
      "<leader>ssw",
      tlscope_builtin.lsp_dynamic_workspace_symbols,
      "Tele[S]cope [W]orkspace [S]ymbols"
    )
    map(
      "<leader>st",
      tlscope_builtin.lsp_type_definitions,
      "Tele[S]cope [T]ype [D]efinition"
    )

    -- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
    ---@param client vim.lsp.Client
    ---@param method vim.lsp.protocol.Method
    ---@param bufnr? integer some lsp support methods only in specific files
    ---@return boolean
    local function client_supports_method(client, method, bufnr)
      if vim.fn.has("nvim-0.11") == 1 then
        return client:supports_method(method, bufnr)
      else
        return client.supports_method(method, { bufnr = bufnr })
      end
    end

    -- The following two autocommands are used to highlight references of the
    -- word under your cursor when your cursor rests there for a little while.
    --    See `:help CursorHold` for information about when this is executed
    --
    -- When you move your cursor, the highlights will be cleared (the second autocommand).
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if
      client
      and client_supports_method(
        client,
        vim.lsp.protocol.Methods.textDocument_documentHighlight,
        event.buf
      )
    then
      local highlight_augroup = vim.api.nvim_create_augroup(
        "kickstart-lsp-highlight",
        { clear = false }
      )
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd("LspDetach", {
        group = vim.api.nvim_create_augroup(
          "kickstart-lsp-detach",
          { clear = true }
        ),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds({
            group = "kickstart-lsp-highlight",
            buffer = event2.buf,
          })
        end,
      })
    end

    -- The following code creates a keymap to toggle inlay hints in your
    -- code, if the language server you are using supports them
    --
    -- This may be unwanted, since they displace some of your code
    if
      client
      and client_supports_method(
        client,
        vim.lsp.protocol.Methods.textDocument_inlayHint,
        event.buf
      )
    then
      map("<leader>th", function()
        vim.lsp.inlay_hint.enable(
          not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf })
        )
      end, "[T]oggle Inlay [H]ints")
    end
  end,
})

-- lazygit
vim.keymap.set({ "n", "i" }, "<leader>gg", ":LazyGit<CR>")
-- make gitlazy plugin open files in current nvim
function EditLineFromLazygit(file_path, line)
  local path = vim.fn.expand("%:p")
  if path == file_path then
    vim.cmd(tostring(line))
  else
    vim.cmd("e " .. file_path)
    vim.cmd(tostring(line))
  end
end

function EditFromLazygit(file_path)
  local path = vim.fn.expand("%:p")
  if path == file_path then
    return
  else
    vim.cmd("e " .. file_path)
  end
end

vim.deprecate = function(...) end

-- temp
vim.keymap.set("n", "<leader>od", vim.diagnostic.open_float)
vim.keymap.set(
  "n",
  "<leader>dcb",
  "<cmd>bd<cr>",
  { desc = "[D]elete [C]urrent [B]uffer" }
)
