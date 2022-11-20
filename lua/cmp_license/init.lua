local cmp = require('cmp')

local source = {}

source.new = function()
    return setmetatable({}, { __index = source })
end

source.get_trigger_characters = function()
    return { '!' }
end


source.get_license_dir = function(_, callback)
    local dir = os.getenv('HOME') .. '/.local/share/license/scripts';
    return dir
end


function source:is_available()
    local filename = vim.fn.expand('%:t')
    return filename:match('^LICENSE-.*')
end

source.complete = function(self, params, callback)
    local items = {}
    local fs, err = vim.loop.fs_scandir(self:get_license_dir(params, callback))
    if err then
        return callback(err, nil)
    end

    while true do
        local name, fs_type, e = vim.loop.fs_scandir_next(fs)
        if e then
            return callback(fs_type, nil)
        end
        if not name then
            break
        end

        local label = nil
        for c in name:gmatch("-(.*)") do
            label = c
        end

        if not label then
            break
        end

        local insertText = nil
        -- INFO: this is horribly inperformant.. but hey -- how often do you add a new license?
        -- TODO: convert to `luv.spawn` https://github.com/octaltree/cmp-look/blob/master/lua/cmp_look/init.lua#L174
        license_cmd_stdout = io.popen(
            os.getenv('HOME')
            .. '/.local/share/license/license'
            .. ' ' .. label
            .. ' 2>/dev/null')

        table.insert(items, {
            label = label,
            kind = cmp.lsp.CompletionItemKind.File,
            insertText = license_cmd_stdout:read('*a'),
            documentation = label .. ' License',
        })
        license_cmd_stdout:close()

    end

    callback({items = items})
end

return source

