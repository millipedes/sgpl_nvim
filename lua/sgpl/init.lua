local M = {}

function M.setup(opts)
  opts = opts or {}

  -- Register filetype
  vim.filetype.add({
    extension = {
      sgpl = "sgpl",
    },
  })

  -- Set up LSP
  local lsp_path = opts.lsp_cmd or {
    "lua",
    vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h") .. "/lsp.lua"
  }

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "sgpl",
    callback = function()
      vim.lsp.start({
        name = "sgpl-lsp",
        cmd = lsp_path,
        root_dir = vim.fs.dirname(
          vim.fs.find({ ".git", "CMakeLists.txt" }, { upward = true })[1]
        ),
      })
    end,
  })

  -- Buffer options for SGPL files
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "sgpl",
    callback = function()
      vim.bo.commentstring = "# %s"
      vim.bo.tabstop = 2
      vim.bo.shiftwidth = 2
      vim.bo.expandtab = true
    end,
  })
end

return M
