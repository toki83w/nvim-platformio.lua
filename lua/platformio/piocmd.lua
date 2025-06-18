local utils = require("platformio.utils")
local M = {}

function M.piocmd(cmd_table)
    if not utils.pio_install_check() then
        return
    end

    if not utils.cd_pioini() then
        return
    end

    utils.autosave()

    if cmd_table[1] == "" then
        vim.cmd("43ToggleTerm direction=float")
    else
        local cmd = "pio "
        for _, v in pairs(cmd_table) do
            cmd = cmd .. " " .. v
        end
        utils.ToggleTerminal(cmd, "float")
    end
end

return M
