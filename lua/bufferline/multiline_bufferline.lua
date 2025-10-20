-- lua/multiline_bufferline.lua のようなファイルに保存

local M = {}

-- 2行目ウィンドウの状態を保持する変数
local win_id = nil
local buf_nr = nil

-- 2行目のバッファラインを描画・更新するメイン関数
function M.update()
  -- =============================================
  -- 1. バッファを計算する
  -- =============================================
  local buffers_per_line = 8 -- 1行あたりのバッファ数

  local bufs_info = vim.fn.getbufinfo({ buflisted = 1 })

  -- 2行目に表示するバッファがない場合はウィンドウを閉じて終了
  if #bufs_info <= buffers_per_line then
    if win_id and vim.api.nvim_win_is_valid(win_id) then
      vim.api.nvim_win_close(win_id, true)
      win_id = nil
    end
    return
  end

  -- =============================================
  -- 2. ウィンドウとバッファを準備する
  -- =============================================
  -- 既存のウィンドウがなければ作成する
  if not (win_id and vim.api.nvim_win_is_valid(win_id)) then
    -- 2行目専用のバッファを作成（ファイルに紐付かない、scratchバッファ）
    buf_nr = vim.api.nvim_create_buf(false, true)
    
    -- フローティングウィンドウを作成
    win_id = vim.api.nvim_open_win(buf_nr, false, {
      relative = 'editor', -- Neovim全体を基準に配置
      style = 'minimal',   -- ボーダーなどを非表示
      width = vim.o.columns, -- 画面幅いっぱい
      height = 1,          -- 高さ1行
      row = 1,             -- 上から1行目 (0が最上部なので、bufferlineの真下)
      col = 0,
      focusable = false,   -- このウィンドウにフォーカスが当たらないようにする
      noautocmd = true,
    })
  end

  -- =============================================
  -- 3. 2行目を描画する
  -- =============================================
  local second_line_content = {}
  for i = buffers_per_line + 1, #bufs_info do
    local buf_info = bufs_info[i]
    local buf_name = vim.fn.fnamemodify(buf_info.name, ':t')
    if buf_name == '' then buf_name = '[No Name]' end
    table.insert(second_line_content, ' ' .. buf_name .. ' ')
  end

  -- バッファの内容を書き換える
  vim.api.nvim_buf_set_lines(buf_nr, 0, -1, false, { table.concat(second_line_content, '|') })
end

-- セットアップ関数（autocmdを登録する）
function M.setup()
  -- bufferlineの設定からはcustom_areasなどを全て削除してシンプルにする
  require('bufferline').setup({
    -- ここはシンプルな設定のみ
    options = {
      separator_style = 'slant',
    }
  })

  local group = vim.api.nvim_create_augroup('MultilineBufferline', { clear = true })
  -- バッファリストの変更、タブの変更、ウィンドウサイズ変更時にupdate関数を呼び出す
  vim.api.nvim_create_autocmd({ 'BufAdd', 'BufDelete', 'TabEnter', 'WinResized' }, {
    group = group,
    callback = M.update,
  })
  
  -- 起動時にも一度実行
  M.update()
end

return M