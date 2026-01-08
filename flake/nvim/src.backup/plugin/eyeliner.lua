if vim.g.did_load_eyeliner_plugin then
  return
end
vim.g.did_load_eyeliner_plugin = true

require('eyeliner').setup {
  highlight_on_key = true,
  dim = true,
}
