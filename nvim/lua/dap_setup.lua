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

dap.adapters.cpp_remote = {
  type = 'executable',
  command = 'gdb',
  args = { '--interpreter=dap' },
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
    name = "Remote Debug",
    type = "cpp_remote",       -- matches adapter
    request = "launch",
    program = detect_executable,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    setupCommands = {
      {
        text = "target remote localhost:3333",  -- adjust port
        description = "Connect to remote gdbserver",
        ignoreFailures = false
      }
    }
  }
}

dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp

-- ---------------------------
-- UI and virtual text
-- ---------------------------
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
--        "repl",
        "console",
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

