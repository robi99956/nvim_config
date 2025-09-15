local dap = require("dap")
local dapui = require("dapui")
dap.set_log_level('TRACE')

function detect_executable()
  local cwd = vim.fn.getcwd()
  local build_dir = cwd .. "/build"

  if vim.fn.isdirectory(build_dir) == 0 then
    vim.notify("No build directory found", vim.log.levels.ERROR)
    return vim.fn.input('Path to executable: ', cwd .. '/', 'file')
  end

  -- Gather candidate executables
  local execs = {}
  local out_files = vim.fn.glob(build_dir .. "/*.out", false, true)

  if #out_files > 0 then
    execs = out_files
  else
    local files = vim.fn.glob(build_dir .. "/*", false, true)
    for _, f in ipairs(files) do
      if vim.fn.isdirectory(f) == 0 and vim.fn.getfperm(f):match("x") then
        table.insert(execs, f)
      end
    end
  end

  local chosen
  if #execs == 1 then
    chosen = execs[1]
  elseif #execs > 1 then
    chosen = vim.fn.input('Select executable: ', execs[1], 'file')
  else
    chosen = vim.fn.input('Path to executable: ', build_dir .. '/', 'file')
  end

  if vim.fn.filereadable(chosen) == 0 or vim.fn.executable(chosen) == 0 then
    vim.notify("Selected file is not executable: " .. chosen, vim.log.levels.ERROR)
    return nil
  end

  -- Check if it has debug symbols
  local handle = io.popen('file "' .. chosen .. '"')
  local result = handle:read("*a")
  handle:close()

  if not result:match("not stripped") then
    vim.notify("Warning: selected binary may be stripped (no debug symbols)", vim.log.levels.WARN)
  end

  vim.notify("Debugging: " .. chosen, vim.log.levels.INFO)
  return chosen
end


-- ---------------------------
-- Adapter: GDB
-- ---------------------------
dap.adapters.cpp_local = {
  type = 'executable',
  command = 'gdb',
  args = { '--interpreter=dap' },
}

dap.adapters.cppdbg = {
  id = 'cppdbg',
  type = 'executable',
  command = '/home/robert/workspace/vscode-cpptools/extension/debugAdapters/bin/OpenDebugAD7',
  args = {},
}

dap.configurations.cpp = {
  {
    name = "Launch executable",
    type = "cpp_local",
    request = "launch",
    program = detect_executable,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
  {
    name = 'Remote server',
    type = 'cppdbg',
    request = 'launch',
    MIMode = 'gdb',
    miDebuggerServerAddress = 'localhost:2331',
    miDebuggerPath = 'arm-none-eabi-gdb',
    cwd = '${workspaceFolder}',
    program = detect_executable,
  },
}

dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp

-- ---------------------------
-- UI and virtual text
-- ---------------------------
--local _cheat = { buf = nil, win = nil }
--
--local function open_cheatsheet()
--  if _cheat.win and vim.api.nvim_win_is_valid(_cheat.win) then return end
--
--  if not _cheat.buf or not vim.api.nvim_buf_is_valid(_cheat.buf) then
--    _cheat.buf = vim.api.nvim_create_buf(false, true) -- scratch, listed=false
--    vim.api.nvim_buf_set_lines(_cheat.buf, 0, -1, false, {
--      "F5:Continue  |  F6:Pause  |  F10:Step Over  |  F11:Step Into  |  F12:Step Out"
--    })
--    vim.api.nvim_buf_set_option(_cheat.buf, "bufhidden", "wipe")
--    vim.api.nvim_buf_set_option(_cheat.buf, "modifiable", false)
--  end
--
--  local width = math.min(80, vim.o.columns - 4) -- avoid exceeding terminal width
--  local height = 1
--  local opts = {
--    relative = "editor",
--    row = 0,            -- 0-based; adjust to move up/down
--    col = 0,            -- 0-based; adjust to move left/right
--    width = width,
--    height = height,
--    style = "minimal",
--    focusable = false,
--    border = "none",
--  }
--
--  _cheat.win = vim.api.nvim_open_win(_cheat.buf, false, opts)
--  vim.api.nvim_win_set_option(_cheat.win, "wrap", false)
--  vim.api.nvim_win_set_option(_cheat.win, "winhl", "Normal:Normal") -- avoid weird highlighting
--end
--
--local function close_cheatsheet()
--  if _cheat.win and vim.api.nvim_win_is_valid(_cheat.win) then
--    pcall(vim.api.nvim_win_close, _cheat.win, true)
--  end
--  _cheat.win = nil
--  -- keep buffer so reopening is fast; it will be wiped by bufhidden if closed permanently
--end
--
---- Show on debug start, hide on end/exit
--dap.listeners.after.event_initialized["my_cheatsheet"] = function()
--  open_cheatsheet()
--end
--dap.listeners.before.event_terminated["my_cheatsheet"] = function()
--  close_cheatsheet()
--end
--dap.listeners.before.event_exited["my_cheatsheet"] = function()
--  close_cheatsheet()
--end

require("nvim-dap-virtual-text").setup()
dapui.setup({
  layouts = {
    {
      elements = {
        { id = "scopes", size = 0.4 },
        { id = "breakpoints", size = 0.2 },
        { id = "stacks", size = 0.2 },
        { id = "watches", size = 0.2 },
      },
      size = 40, -- width in columns
      position = "left",
    },
    {
      elements = {
        "repl",
      },
      size = 15, -- height in lines
      position = "bottom",
    },
  },
  controls = {
    enabled = true, -- shows play/pause/step buttons at top of UI
  },
})

dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

-- ---------------------------
-- Breakpoints
-- ---------------------------
vim.keymap.set('n', '<F9>', function()
  dap.toggle_breakpoint()
end)

vim.keymap.set('n', '<leader>db', function()
  dap.list_breakpoints()
end)

-- ---------------------------
-- Debug flow 
-- ---------------------------
local opts = { noremap = true, silent = true }

-- Stepping and debugging with single keys + modifiers
vim.keymap.set('n', '<C-n>', dap.step_over, opts)   -- Ctrl+n = next (step over)
vim.keymap.set('n', '<C-i>', dap.step_into, opts)   -- Ctrl+i = step into
vim.keymap.set('n', '<C-o>', dap.step_out, opts)    -- Ctrl+o = step out
vim.keymap.set('n', '<C-c>', dap.continue, opts)    -- Ctrl+c = continue
vim.keymap.set('n', '<C-b>', dap.toggle_breakpoint, opts) -- Ctrl+b = toggle breakpoint
vim.keymap.set('n', '<C-s>', dap.pause, opts)       -- Ctrl+p = pause

-- ---------------------------
-- Start/stop commands
-- ---------------------------
vim.api.nvim_create_user_command('DebugLocal', function()
  require('dap').run(dap.configurations.cpp[1])
end, {})

vim.api.nvim_create_user_command('DebugRemote', function()
  require('dap').run(dap.configurations.cpp[2])
end, {})

vim.api.nvim_create_user_command('DebugStop', function()
  dap.terminate()
end, {})

