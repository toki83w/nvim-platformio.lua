local M = {}

local utils = require("platformio.utils")

function M.piobuild()
    if not utils.cd_pioini() then
        return
    end

    utils.autosave()

    local command = "pio run" .. utils.env_args()
    utils.ToggleTerminal(command, "tab")
end

function M.pioupload()
    if not utils.cd_pioini() then
        return
    end

    utils.autosave()

    local command = "pio run --target upload" .. utils.env_args()
    utils.ToggleTerminal(command, "tab")
end

function M.piouploadfs()
    if not utils.cd_pioini() then
        return
    end

    utils.autosave()

    local command = "pio run --target uploadfs" .. utils.env_args()
    utils.ToggleTerminal(command, "tab")
end

function M.pioclean()
    if not utils.cd_pioini() then
        return
    end

    utils.autosave()

    local command = "pio run --target clean" .. utils.env_args()
    utils.ToggleTerminal(command, "tab")
end

function M.piorun(arg_table)
    if not utils.pio_install_check() then
        return
    end
    if arg_table[1] == "" then
        M.pioupload()
    elseif arg_table[1] == "upload" then
        M.pioupload()
    elseif arg_table[1] == "uploadfs" then
        M.piouploadfs()
    elseif arg_table[1] == "build" then
        M.piobuild()
    elseif arg_table[1] == "clean" then
        M.pioclean()
    else
        vim.notify("Invalid argument: build, upload, uploadfs or clean", vim.log.levels.WARN)
    end
end

return M
