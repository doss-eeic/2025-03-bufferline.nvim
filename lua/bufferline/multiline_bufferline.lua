-- lua/bufferline/multiline_bufferline.lua
local M = {}

-- 状態管理
local win_id, buf_nr

-- 2行目バッファライン更新
function M.update()
  local per_line = 8
  local bufs = vim.fn.getbufinfo({ buflisted = 1 })

  -- バッファ数が少ない場合は閉じる
  if #bufs <= per_line then
    if win_id and vim.api.nvim_win_is_valid(win_id) then
      vim.api.nvim_win_close(win_id, true)
      win_id = nil
    end
    return
  end

  -- ウィンドウ未作成なら作成
  if not (win_id and vim.api.nvim_win_is_valid(win_id)) then
    buf_nr = vim.api.nvim_create_buf(false, true)
    win_id = vim.api.nvim_open_win(buf_nr, false, {
      relative = 'editor',
      style = 'minimal',
      width = vim.o.columns,
      height = 1,
      row = 1,
      col = 0,
      focusable = false,
      noautocmd = true,
    })
  end

  -- 2行目の内容を生成
  local names = {}
  for i = per_line + 1, #bufs do
    local name = vim.fn.fnamemodify(bufs[i].name, ':t')
    table.insert(names, ' ' .. (name ~= '' and name or '[No Name]') .. ' ')
  end

  vim.api.nvim_buf_set_lines(buf_nr, 0, -1, false, { table.concat(names, '|') })
end

-- セットアップ
function M.setup()
  require('bufferline').setup({
    options = { separator_style = 'slant' }
  })

  local g = vim.api.nvim_create_augroup('MultilineBufferline', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufAdd', 'BufDelete', 'TabEnter', 'WinResized' }, {
    group = g,
    callback = M.update,
  })

  M.update()
end

return M
