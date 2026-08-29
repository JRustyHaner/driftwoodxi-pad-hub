package.path = 'addons/dwhub/?.lua;' .. package.path;

local cmds = require('cmds');
local screens = require('screens');

describe('fish screen', function()
    local queued = {};
    local ctx = {
        enqueue = function(command)
            queued[#queued + 1] = command;
        end,
        set_status = function() end,
    };

    before_each(function()
        queued = {};
    end);

    it('builds fish guide commands', function()
        assert.equals('!fish', cmds.fish_status());
        assert.equals('!fish next', cmds.fish_next());
        assert.equals('!fish rank', cmds.fish_rank());
        assert.equals('!fish route', cmds.fish_route());
    end);

    it('lists four fish rows per #47', function()
        local screen = screens.fish(ctx);
        local rows = screen:rows();
        assert.equals(4, #rows);
        assert.equals('Status', rows[1].label);
        assert.equals('Next catch', rows[2].label);
        assert.equals('Rank cap', rows[3].label);
        assert.equals('Full route', rows[4].label);
    end);

    it('queues commands from each row', function()
        local screen = screens.fish(ctx);
        for index = 1, 4 do
            screen.on_confirm(screen, index, { push = function() end });
        end
        assert.same({
            '!fish',
            '!fish next',
            '!fish rank',
            '!fish route',
        }, queued);
    end);
end);
