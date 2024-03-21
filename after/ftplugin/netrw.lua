vim.keymap.set('n', '<C-l>', function()
  require('nvim-tmux-navigation').NvimTmuxNavigateRight()
end, { silent = true, buffer = true })
