local Teleport = {}

-- Helpers
local function boolean(value) return value == 1 end

local function blink_line(line_num, callback)
    local interval = 80
    local ns_id = vim.api.nvim_create_namespace('blink_line_ns')

    vim.api.nvim_buf_add_highlight(0, ns_id, 'Visual', line_num - 1, 0, -1)

    vim.defer_fn(function()
        vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
        if callback then callback() end
    end, interval)
end

-- create highlight group
-- TODO: dynamicaly set colors
vim.api.nvim_command('highlight CharHighlight guibg=#FFD700 guifg=#000000')

-- available characters for higlights replacement
local replacement_characters =
    "weasdzxcrfjklnvgb6yh7um12345890QWEASDZXCRFJKLNVGB6Y7UMH"
local replacement_char_index = 1

-- get all existing keymaps so we can restore them later
local original_mappings = {}
local all_existing_keymaps = vim.api.nvim_get_keymap("n")

-- restores the original mappings and clears the used keymaps
local function restore_mappings()
    -- clear replacement keymaps
    for char in replacement_characters:gmatch(".") do
        local success = pcall(vim.api.nvim_buf_del_keymap, 0, 'n', char)
        if not success then break end
    end

    -- restore original mappings
    for _, keymap in pairs(original_mappings) do
        vim.keymap.set('n', keymap.lhs, keymap.rhs, {
            noremap = boolean(keymap.noremap),
            silent = boolean(keymap.silent),
            buffer = keymap.buffer
        })
    end
    original_mappings = {}
end

-- store every highlighted position with the associated replacement character
local highlighted_positions = {}

-- get a character from the replacement_characters string. Used to replace the highlighted characters so we can jump to them
local function get_replacement_character()
    local char = replacement_characters:sub(replacement_char_index,
                                            replacement_char_index)
    if replacement_char_index > #replacement_characters then
        return
    else
        replacement_char_index = replacement_char_index + 1
    end
    return char
end

-- clear the highlights and virtual text
local function clear_highlights()
    vim.api.nvim_buf_clear_namespace(0, Teleport.namespace, 0, -1)
end

-- reset the state of the plugin
Teleport.reset_state = function()
    replacement_char_index = 1
    highlighted_positions = {}
    clear_highlights()
    restore_mappings()
end

-- highlight and replace matching characters with random unique chars
local function highlight_visible_lines(char, direction)
    -- get the range of visible lines
    local current_line = vim.fn.line('.')
    local start_line = vim.fn.line("w0") - 1
    local end_line = vim.fn.line("w$") - 1

    if direction == 'forwards' then
        start_line = current_line - 1
    elseif direction == 'backwards' then
        end_line = current_line - 1
    end

    local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line + 1, false)
    for row, line in ipairs(lines) do
        local start_pos = 1
        while true do
            local start_idx, end_idx = string.find(line, char, start_pos, true)
            if not start_idx then break end

            local replacement_char = get_replacement_character()
            if not replacement_char then return end

            -- apply highlight
            vim.api.nvim_buf_add_highlight(0, Teleport.namespace,
                                           "CharHighlight",
                                           start_line + row - 1, start_idx - 1,
                                           end_idx)

            -- add virtual text overlay with the replacement character
            vim.api.nvim_buf_set_extmark(0, Teleport.namespace,
                                         start_line + row - 1, start_idx - 1, {
                virt_text = {{replacement_char, "CharHighlight"}},
                virt_text_pos = "overlay"
            })

            -- store the position associated with the random character
            highlighted_positions[replacement_char] = {
                start_line + row - 1, start_idx - 1
            }

            -- store the previous mapping for this character so we can restore it later
            for _, keymap in ipairs(all_existing_keymaps) do
                if keymap.lhs == replacement_char and
                    not original_mappings[keymap.lhs] then
                    original_mappings[keymap.lhs] = keymap
                end
            end

            -- create a mapping to jump to this character's position
            vim.keymap.set("n", tostring(replacement_char), function()
                Teleport.jump_to_highlight(replacement_char)
                Teleport.reset_state()
            end, {noremap = true, silent = true, buffer = 0})

            start_pos = end_idx + 1
        end
    end
end

-- jump to a specific highlighted position
function Teleport.jump_to_highlight(replacement_char)
    local pos = highlighted_positions[replacement_char]
    if pos then
        vim.api.nvim_win_set_cursor(0, {pos[1] + 1, pos[2]})
        blink_line(pos[1] + 1)
    end
end

function Teleport.init(direction)
    local char = vim.fn.getchar()
    if type(char) == "number" then
        char = vim.fn.nr2char(char)
        highlight_visible_lines(char, direction)
    end
end

-- initialize namespace for highlighting
Teleport.namespace = vim.api.nvim_create_namespace("highlight_char_namespace")

Teleport.setup = function()
    -- command to trigger the function
    vim.api.nvim_create_user_command("Teleport", function(args)
        Teleport.init(args.args)
    end, {nargs = "*"})
    vim.api.nvim_create_user_command("TeleportExit",
                                     function() Teleport.reset_state() end,
                                     {nargs = "*"})

    -- set keymaps
    -- vim.keymap.set('n', 'qq', function() Teleport.reset_state() end,
    -- {noremap = true})

    -- vim.keymap.set("n", "t", function() Teleport.init('forwards') end,
    -- {noremap = true})
    -- vim.keymap.set("n", "T", function() Teleport.init('backwards') end,
    -- {noremap = true})
end

return {setup = Teleport.setup}
