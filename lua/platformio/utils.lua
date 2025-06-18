local M = {}

function M.strsplit(inputstr, del)
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. del .. "]+)") do
        table.insert(t, str)
    end
    return t
end

----------------------------------------------------------------------------------------

local t43
function M.ToggleTerminal(command, direction, on_exit, count)
    local Terminal = require("toggleterm.terminal").Terminal

    count = count or 43
    local is_t43 = count == 43

    if is_t43 and t43 then
        t43:shutdown()
    end

    local t = Terminal:new({
        cmd = command,
        direction = direction,
        close_on_exit = false,
        count = count,
        start_in_insert = false,
        auto_scroll = true,

        on_exit = on_exit,
    })

    t:toggle()

    if is_t43 then
        t43 = t
    end
end

local is_windows = jit.os == "Windows"
M.devNul = is_windows and " 2>./nul" or " 2>/dev/null"

----------------------------------------------------------------------------------------

function M.file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

function M.cd_pioini(skip_notify)
    if not M.file_exists("platformio.ini") then
        if not skip_notify then
            vim.notify("platformio.ini not found in current directory", vim.log.levels.ERROR)
        end
        return false
    end
    return true
end

function M.pio_install_check()
    local handel = (jit.os == "Windows") and assert(io.popen("where.exe pio 2>./nul"))
        or assert(io.popen("which pio 2>/dev/null"))
    local pio_path = assert(handel:read("*a"))
    handel:close()

    if #pio_path == 0 then
        vim.notify("Platformio not found in the path", vim.log.levels.ERROR)
        return false
    end
    return true
end

function M.autosave()
    local config = require("platformio").config
    if config.autosave then
        vim.cmd("wa")
    end
end

----------------------------------------------------------------------------------------

M.default_env = "__default__"

M.env_args = function()
    local env = require("platformio").config.active_env
    return env == M.default_env and "" or (" -e " .. env)
end

M.get_envs = function()
    local envs = { M.default_env }

    local parse_ini = function()
        for line in io.lines("platformio.ini") do
            local _, _, env = string.find(line, "^%[env:(%S+)%]$")
            if env then
                print("environment:", env)
                table.insert(envs, env)
            end
        end
    end

    if pcall(parse_ini) then
        return envs
    else
        return {}
    end
end

----------------------------------------------------------------------------------------

M.pick_string = function(title, prompt, strings, callback)
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local telescope_conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    local opts = {}
    pickers
        .new(opts, {
            prompt_title = prompt,
            results_title = title,
            finder = finders.new_table({
                results = strings,
            }),
            attach_mappings = function(prompt_bufnr, _)
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                    local selection = action_state.get_selected_entry()
                    callback(selection[1])
                end)
                return true
            end,
            sorter = telescope_conf.generic_sorter(opts),
        })
        :find()
end

M.write_file = function(path, content)
    local dir = vim.fs.dirname(path)

    if not vim.fn.mkdir(dir, "p") then
        vim.notify("Failed to create directory: " .. dir, vim.log.levels.ERROR)
        return false
    end

    local file, err = io.open(path, "w")

    if not file then
        vim.notify("Failed to write file " .. path .. ": " .. err, vim.log.levels.ERROR)
        return false
    end

    file:write(content)
    file:close()

    return true
end

M.append_file = function(path, content)
    local file, err = io.open(path, "a")

    if not file then
        vim.notify("Failed to append file " .. path .. ": " .. err, vim.log.levels.ERROR)
        return false
    end

    file:write(content)
    file:close()

    return true
end

M.delete_file = function(path)
    return vim.fn.delete(path) == 0
end

----------------------------------------------------------------------------------------

local decode_json = function(path)
    local file = io.open(path, "rb")

    if not file then
        return {}
    end

    local content = file:read("*a")
    file:close()

    return vim.json.decode(content) or {}
end

M.get_json_conf = function()
    local path = vim.fs.joinpath(".nvim", "pio.json")

    if not M.file_exists(path) then
        return nil
    end

    return decode_json(path)
end

M.set_json_conf = function(pio)
    if not M.cd_pioini() then
        return false
    end

    return M.write_file(vim.fs.joinpath(".nvim", "pio.json"), vim.json.encode(pio))
end

M.json_conf = function(data)
    local pio = M.get_json_conf() or {}
    pio = vim.tbl_deep_extend("force", pio, data or {})
    return M.set_json_conf(pio)
end

----------------------------------------------------------------------------------------

return M
