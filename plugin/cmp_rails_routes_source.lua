local debounce = require('telescope.debounce').debounce_leading
local Job = require 'plenary.job'
local script_path = vim.fn.stdpath 'config' .. '/scripts/rails_routes_to_json.rb'
local items = {}
local w = vim.loop.new_fs_event()

-- local function show_in_split(data)
--   vim.schedule(function()
--     -- Erzeugt einen neuen horizontalen Split
--     vim.cmd 'new'
--     -- Setzt den Inhalt des aktuellen Puffers auf die inspizierte Daten
--     vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(vim.inspect(data), '\n'))
--   end)
-- end

local function start_watching_routes()
  if w then
    w:stop()
  else
    w = vim.loop.new_fs_event()
  end

  local on_change, watch_file
  on_change = debounce(function(err)
    if err then
      w:stop()
      return
    end

    -- Do work...
    Job:new({
      command = 'bundle',
      args = { 'exec', 'ruby', script_path },
      -- on_stdout = function(_, data)
      --   -- Plant das Schreiben der stdout-Daten in die Logdatei
      --   vim.schedule(function()
      --     vim.fn.writefile({ data }, log_path, 'a')
      --   end)
      -- end,
      -- on_stderr = function(_, data)
      --   -- Plant das Schreiben der stderr-Daten in die Logdatei
      --   vim.schedule(function()
      --     vim.fn.writefile({ data }, log_path, 'a')
      --   end)
      -- end,
      on_exit = function(j, return_val)
        if return_val == 0 then
          local ok, routes = pcall(vim.json.decode, table.concat(j:result(), '\n'))
          if ok then
            -- Umwandeln der `routes` in das erwartete Format
            items = {}
            for _, route in ipairs(routes) do
              table.insert(items, {
                label = string.format('%s_path', route.route),
                kind = vim.lsp.protocol.CompletionItemKind.Method,
              })
              table.insert(items, {
                label = string.format('%s_url', route.route),
                kind = vim.lsp.protocol.CompletionItemKind.Method,
              })
            end
            -- show_in_split(items)
          else
            print 'Fehler beim Decodieren der JSON-Ausgabe'
          end
        else
          print('Ruby-Skript fehlgeschlagen mit return_val: ', return_val)
        end
      end,
    }):start()
  end, 1000)

  watch_file = function(fname)
    local fullpath = vim.api.nvim_call_function('fnamemodify', { fname, ':p' })
    w:start(fullpath, { recursive = true }, on_change)
  end

  on_change(nil)
  watch_file 'config/'
end

local function stop_watching_routes()
  w:stop()
  w = nil
end

local source = {}

source.complete = function(self, _, callback)
  callback(items)
end

source.is_available = function()
  return vim.bo.filetype == 'eruby'
end

vim.api.nvim_create_autocmd('BufEnter', {
  desc = 'Searching for rails routes to provide helper names',
  group = vim.api.nvim_create_augroup('rails-route-helpers', { clear = true }),
  callback = function()
    if vim.fn.filereadable 'Gemfile' > 0 then
      start_watching_routes()
    end
  end,
})

require('cmp').register_source('rails_route_helpers', source)
