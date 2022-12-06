local api = vim.api

-- Start Netrw when editor is launched
local initNetrwGroup = api.nvim_create_augroup("InitNetrw", { clear = true })
api.nvim_create_autocmd("VimEnter", {
  pattern = "*",
  command = [[if expand("%") == "" | silent! Explore | endif]],
  group = initNetrwGroup,
})
