local M = {}

local config = require('platformio').config
local utils = require 'platformio.utils'

function M.pioenv()
  if not utils.pio_install_check() then
    return
  end

  if not utils.cd_pioini() then
    return
  end

  local envs = utils.get_envs()
  if #envs == 0 then
    return
  end

  utils.pick_string('Environments', 'Select active environment', envs, function(selected_env)
    config.active_env = selected_env
    vim.notify('Active environment: ' .. selected_env, vim.log.levels.INFO)
    utils.json_conf { active_env = selected_env }
    if config.lsp == 'clangd' then
      local command = 'pio run -t compiledb' .. utils.env_args() .. utils.extra
      utils.ToggleTerminal(command, 'float')
    end
  end)
end

return M
