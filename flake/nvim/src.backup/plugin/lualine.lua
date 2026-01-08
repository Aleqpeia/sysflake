if vim.g.did_load_lualine_plugin then
  return
end
vim.g.did_load_lualine_plugin = true

local navic = require('nvim-navic')
navic.setup {}

local function extra_mode_status()
  local reg_recording = vim.fn.reg_recording()
  if reg_recording ~= '' then
    return ' @' .. reg_recording
  end
  local reg_executing = vim.fn.reg_executing()
  if reg_executing ~= '' then
    return ' @' .. reg_executing
  end
  local mode = vim.api.nvim_get_mode().mode
  if mode == 'ix' then
    return '^X: (^]^D^E^F^I^K^L^N^O^Ps^U^V^Y)'
  end
  return ''
end

require('lualine').setup {
  globalstatus = true,
  sections = {
    lualine_c = {
      { navic.get_location, cond = navic.is_available },
    },
    lualine_z = {
      { extra_mode_status },
    },
  },
  options = {
    theme = 'auto',
  },
  winbar = {
    lualine_z = {
      {
        'filename',
        path = 1,
        file_status = true,
        newfile_status = true,
      },
    },
  },
  extensions = { 'fugitive', 'fzf', 'toggleterm', 'quickfix' },
}
