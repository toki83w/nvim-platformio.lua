local utils = require("platformio.utils")
local M = {}

function M.piodebug(args_table)
    if not utils.pio_install_check() then
        return
    end

    if not utils.cd_pioini() then
        return
    end

    utils.autosave()

    local command = "pio debug --interface=gdb -- -x .pioinit"
    utils.ToggleTerminal(command, "tab")
end

return M
