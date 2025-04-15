local utils = require("platformio.utils")
local M = {}

function M.piodebug(args_table)
    if not utils.pio_install_check() then
        return
    end

    if not utils.cd_pioini() then
        return
    end

    local command = string.format("pio debug --interface=gdb -- -x .pioinit %s", utils.extra)
    utils.ToggleTerminal(command, "tab")
end

return M
