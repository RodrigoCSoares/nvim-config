local M = {}

local config = {
  width = 120,
  neotree_width = 40,
}

local state = {
  enabled = false,
  left_pad = { win = nil, buf = nil },
  right_pad = { win = nil, buf = nil },
  augroup = nil,
  scheduled = false,
}

local function setup_highlights()
  local hl = vim.api.nvim_get_hl(0, { name = "Normal" })
  local bg = hl.bg
  local bg_hex = bg and string.format("#%06x", bg) or "NONE"
  vim.api.nvim_set_hl(0, "CenterCodePad", { bg = bg_hex, fg = bg_hex })
  vim.api.nvim_set_hl(0, "CenterCodeSep", { bg = bg_hex, fg = bg_hex })
end

-- ---------- helpers ----------

local function is_floating(win)
  local cfg = vim.api.nvim_win_get_config(win)
  return cfg.relative ~= ""
end

local function is_padding_win(win)
  return win == state.left_pad.win or win == state.right_pad.win
end

local function is_padding_buf(buf)
  return buf == state.left_pad.buf or buf == state.right_pad.buf
end

local function is_neotree_win(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end
  local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
  if not ok then
    return false
  end
  return vim.bo[buf].filetype == "neo-tree"
end

local function find_neotree_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_neotree_win(win) then
      return win
    end
  end
  return nil
end

local function get_neotree_width()
  local win = find_neotree_win()
  if win then
    return vim.api.nvim_win_get_width(win) + 1
  end
  return 0
end

local function code_wins()
  local result = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if
      vim.api.nvim_win_is_valid(win)
      and not is_floating(win)
      and not is_neotree_win(win)
      and not is_padding_win(win)
    then
      local buf = vim.api.nvim_win_get_buf(win)
      if not is_padding_buf(buf) then
        result[#result + 1] = win
      end
    end
  end
  return result
end

-- ---------- pad management ----------

local function make_pad_buf()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].buflisted = false
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "center-code-pad"
  return buf
end

local function apply_pad_win_opts(win)
  local opts = {
    number = false,
    relativenumber = false,
    signcolumn = "no",
    foldcolumn = "0",
    statuscolumn = "",
    winfixwidth = true,
    cursorline = false,
    cursorcolumn = false,
    colorcolumn = "",
    wrap = false,
    list = false,
    spell = false,
  }
  for k, v in pairs(opts) do
    vim.wo[win][k] = v
  end
  vim.api.nvim_win_set_option(
    win,
    "winhighlight",
    "Normal:CenterCodePad,NormalNC:CenterCodePad,WinSeparator:CenterCodeSep,EndOfBuffer:CenterCodePad"
  )
end

local function destroy_pad(side)
  local pad = state[side]
  if pad.win and vim.api.nvim_win_is_valid(pad.win) then
    pcall(vim.api.nvim_win_close, pad.win, true)
  end
  pad.win = nil
  if pad.buf and vim.api.nvim_buf_is_valid(pad.buf) then
    pcall(vim.api.nvim_buf_delete, pad.buf, { force = true })
  end
  pad.buf = nil
end

local function close_all_pads()
  destroy_pad("left_pad")
  destroy_pad("right_pad")
end

local function ensure_pad(side, code_win, width, split_cmd)
  local pad = state[side]

  if pad.win and vim.api.nvim_win_is_valid(pad.win) then
    pcall(vim.api.nvim_win_set_width, pad.win, width)
    return
  end

  destroy_pad(side)

  pad.buf = make_pad_buf()
  local prev = vim.api.nvim_get_current_win()
  vim.cmd("noautocmd call nvim_set_current_win(" .. code_win .. ")")
  local ok = pcall(vim.cmd, "noautocmd " .. split_cmd)
  if not ok then
    pcall(vim.api.nvim_buf_delete, pad.buf, { force = true })
    pad.buf = nil
    vim.cmd("noautocmd call nvim_set_current_win(" .. prev .. ")")
    return
  end

  pad.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(pad.win, pad.buf)
  vim.api.nvim_win_set_width(pad.win, width)
  apply_pad_win_opts(pad.win)

  vim.cmd("noautocmd call nvim_set_current_win(" .. prev .. ")")
end

-- ---------- core layout ----------

--- Apply centering layout. Pass neotree_override to predict Neo-tree width
--- instead of measuring live (used by before_open / before_close hooks).
local function apply_layout(neotree_override)
  if not state.enabled then
    return
  end

  local cwins = code_wins()
  if #cwins ~= 1 then
    close_all_pads()
    return
  end

  local code_win = cwins[1]
  if not vim.api.nvim_win_is_valid(code_win) then
    return
  end

  local total_width = vim.o.columns
  local desired = config.width

  local total_pad = total_width - desired - 2
  if total_pad < 2 then
    close_all_pads()
    return
  end

  local left_target = math.floor(total_pad / 2)
  local right_target = total_pad - left_target

  local nt_width = neotree_override or get_neotree_width()
  local left_w = left_target - nt_width
  if left_w < 1 then
    left_w = 0
  end
  local right_w = right_target

  local cur = vim.api.nvim_get_current_win()

  if left_w > 0 then
    ensure_pad("left_pad", code_win, left_w, "aboveleft vsplit")
  else
    destroy_pad("left_pad")
  end
  ensure_pad("right_pad", code_win, right_w, "belowright vsplit")

  if vim.api.nvim_win_is_valid(code_win) then
    pcall(vim.api.nvim_win_set_width, code_win, desired)
  end

  if vim.api.nvim_win_is_valid(cur) and not is_padding_win(cur) then
    vim.cmd("noautocmd call nvim_set_current_win(" .. cur .. ")")
  else
    vim.cmd("noautocmd call nvim_set_current_win(" .. code_win .. ")")
  end
end

local function rebalance()
  apply_layout(nil)
end

local function schedule_rebalance()
  if state.scheduled then
    return
  end
  state.scheduled = true
  vim.schedule(function()
    state.scheduled = false
    rebalance()
  end)
end

-- ---------- Neo-tree event hooks (called from neo-tree config) ----------

--- Call BEFORE Neo-tree opens its window.
--- Pre-shrinks the left pad so Neo-tree slides in without shifting code.
function M.before_neotree_open()
  if not state.enabled then
    return
  end
  apply_layout(config.neotree_width + 1)
end

--- Call AFTER Neo-tree opens its window.
--- Fine-tune with the real measured width.
function M.after_neotree_open()
  if not state.enabled then
    return
  end
  rebalance()
end

--- Call BEFORE Neo-tree closes its window.
--- Pre-expands the left pad so closing doesn't shift code.
function M.before_neotree_close()
  if not state.enabled then
    return
  end
  apply_layout(0)
end

--- Call AFTER Neo-tree closes its window.
--- Fine-tune in case the prediction was slightly off.
function M.after_neotree_close()
  if not state.enabled then
    return
  end
  rebalance()
end

-- ---------- public API ----------

function M.enable()
  if state.enabled then
    return
  end
  state.enabled = true

  setup_highlights()

  state.augroup = vim.api.nvim_create_augroup("CenterCode", { clear = true })

  vim.api.nvim_create_autocmd("VimResized", {
    group = state.augroup,
    callback = schedule_rebalance,
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = state.augroup,
    callback = function()
      setup_highlights()
      schedule_rebalance()
    end,
  })

  vim.api.nvim_create_autocmd("WinEnter", {
    group = state.augroup,
    callback = function()
      local win = vim.api.nvim_get_current_win()
      if is_padding_win(win) then
        local cwins = code_wins()
        if #cwins > 0 then
          pcall(vim.api.nvim_set_current_win, cwins[1])
        end
      end
    end,
  })

  -- Fallback for layout changes not caused by Neo-tree
  vim.api.nvim_create_autocmd({ "WinNew", "WinClosed" }, {
    group = state.augroup,
    callback = schedule_rebalance,
  })

  rebalance()
end

function M.disable()
  if not state.enabled then
    return
  end
  state.enabled = false
  close_all_pads()
  if state.augroup then
    pcall(vim.api.nvim_del_augroup_by_id, state.augroup)
    state.augroup = nil
  end
end

function M.toggle()
  if state.enabled then
    M.disable()
  else
    M.enable()
  end
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  vim.api.nvim_create_user_command("CenterCode", function()
    M.toggle()
  end, { desc = "Toggle code centering" })

  vim.api.nvim_create_user_command("CenterCodeRebalance", function()
    rebalance()
  end, { desc = "Force rebalance centering" })

  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      vim.schedule(function()
        M.enable()
      end)
    end,
  })
end

return M
