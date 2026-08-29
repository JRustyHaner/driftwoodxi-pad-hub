package.path = 'addons/dwhub/?.lua;' .. package.path;

local screens = require('screens');

describe('hub category screens', function()
    local ctx = {
        enqueue = function() end,
        set_status = function() end,
    };

    local categories = {
        { fn = 'storage', id = 'storage', title = 'Storage' },
        { fn = 'market', id = 'market', title = 'Market' },
        { fn = 'merc', id = 'merc', title = 'Merc' },
        { fn = 'quests', id = 'quests', title = 'Quests' },
        { fn = 'drift', id = 'drift', title = 'Drift' },
        { fn = 'fish', id = 'fish', title = 'Fish' },
        { fn = 'raid', id = 'raid', title = 'Raid' },
        { fn = 'arena', id = 'arena', title = 'Arena' },
        { fn = 'scan', id = 'scan', title = 'Scan' },
        { fn = 'engage', id = 'engage', title = 'Engage' },
    };

    for _, cat in ipairs(categories) do
        it('loads ' .. cat.title .. ' with rows', function()
            local screen = screens[cat.fn](ctx);
            assert.equals(cat.id, screen.id);
            assert.equals(cat.title, screen.title);
            assert.is_true(#screen:rows() >= 2);
        end);
    end
end);
