local M = {}

-- M.extra = 'printf \"\\\\n\\\\033[0;33mPlease Press ENTER to continue \\\\033[0m\"; read'
M.extra = " && echo . && echo . && echo Please Press ENTER to continue"

function M.strsplit(inputstr, del)
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. del .. "]+)") do
        table.insert(t, str)
    end
    return t
end

----------------------------------------------------------------------------------------

local platformio = vim.api.nvim_create_augroup("platformio", { clear = true })
function M.ToggleTerminal(command, direction, title)
    --
    local Terminal = require("toggleterm.terminal").Terminal
    local terminal = Terminal:new({
        cmd = command,
        direction = direction,
        close_on_exit = false,

        on_open = function(t)
            --Only to set Piomon toggleterm winbar title/message
            if title then
                -- local hl = vim.api.nvim_get_hl(0, { name = "CurSearch" })
                local hl = { bg = "#e4cf0e", fg = "#0012d9" }
                vim.api.nvim_set_hl(0, "MyWinBar", { bg = hl.bg, fg = hl.fg })

                local winBarTitle = "%#MyWinBar#" .. title .. "%*"
                vim.api.nvim_set_option_value("winbar", winBarTitle, { scope = "local", win = t.window })

                -- Following necessary to solve that some time winbar not showing
                vim.schedule(function()
                    vim.api.nvim_set_option_value("winbar", winBarTitle, { scope = "local", win = t.window })
                end)
            end
        end,

        on_create = function(t)
            t.set_mode(t, "i")
            --Only to set Piomon toggleterm winbar title/message
            if title then
                --set toggleterm to be in insert mode

                -- keymap toggleterm "Esc" and ":" keys to go command line
                vim.keymap.set("t", "<Esc>", [[<C-\><C-n>k]], { noremap = true, buffer = t.bufnr })
                vim.keymap.set("n", "<Esc>", [[<C-\><C-n>a]], { noremap = true, buffer = t.bufnr })
                vim.keymap.set("n", "<C-c>", [[<C-\><C-n>a<C-c>]], { noremap = true, buffer = t.bufnr })
                vim.keymap.set("t", ":", [[<C-\><C-n>:]], { noremap = true, buffer = t.bufnr })
                vim.keymap.set("n", ":", [[<C-\><C-n>:]], { noremap = true, buffer = t.bufnr })

                vim.api.nvim_create_autocmd("BufEnter", {
                    group = platformio,
                    desc = "toggleterm buffer entered",
                    buffer = t.bufnr,
                    callback = function(args)
                        t.set_mode(t, "i")
                    end,
                })

                vim.api.nvim_create_autocmd("BufUnload", {
                    group = platformio,
                    desc = "toggleterm buffer unloaded",
                    buffer = t.bufnr,
                    callback = function(args)
                        vim.keymap.del({ "n", "t" }, ":", { buffer = args.buf })
                        vim.keymap.del({ "n", "t" }, "<Esc>", { buffer = args.buf })

                        vim.keymap.del("n", "<C-c>", { buffer = args.buf })
                        vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { noremap = true, buffer = 0 })

                        -- clear autommmand when quit
                        vim.api.nvim_clear_autocmds({ group = "platformio" })
                    end,
                })

                vim.api.nvim_create_autocmd("QuitPre", {
                    group = platformio,
                    desc = "shutdown terminl",
                    buffer = t.bufnr,
                    callback = function()
                        vim.api.nvim_exec_autocmds(
                            "BufUnload",
                            { group = platformio, buffer = t.bufnr, data = t.bufnr }
                        )
                        -- do clean and proper toggleterm shutdown
                        t.set_mode(t, "n")
                        t.shutdown(t)
                    end,
                })

                vim.api.nvim_create_autocmd("ModeChanged", {
                    -- Autocommand for modechanges of toggleterm buffer
                    group = platformio,
                    buffer = t.bufnr,
                    callback = function()
                        local old_mode = vim.v.event.old_mode
                        local new_mode = vim.v.event.new_mode
                        if new_mode == "nt" and old_mode == "c" then
                            -- after entering normal terminal mode comming back from command line mode,
                            -- below force terminal buffer to enter insert mode
                            t.set_mode(t, "i")
                        end
                    end,
                })
            end
        end,
    })
    terminal:toggle()
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

local encode_json = function(path, pio)
    local file = io.open(path, "wb")

    if not file then
        return false
    end

    file:write(vim.json.encode(pio))
    file:close()

    return true
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

    if not vim.fn.mkdir(".nvim", "p") then
        vim.notify("Failed to create directory: .nvim", vim.log.levels.ERROR)
        return false
    end

    local path = vim.fs.joinpath(".nvim", "pio.json")
    if not encode_json(path, pio) then
        vim.notify("Failed to write to file: " .. path, vim.log.levels.ERROR)
        return false
    end

    return true
end

M.json_conf = function(data)
    local pio = M.get_json_conf() or {}
    pio = vim.tbl_deep_extend("force", pio, data or {})
    return M.set_json_conf(pio)
end

----------------------------------------------------------------------------------------

return M
