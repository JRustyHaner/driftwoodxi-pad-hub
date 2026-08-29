package.path = 'addons/dwhub/?.lua;' .. package.path;

local cmds = require('cmds');
local nav = require('nav');
local screens = require('screens');

describe('arena screen', function()
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

    it('builds arena commands', function()
        assert.equals('!arena', cmds.arena_board());
        assert.equals('!arena enter', cmds.arena_enter());
        assert.equals('!arena leave', cmds.arena_leave());
    end);

    it('lists three arena rows per #48', function()
        local screen = screens.arena(ctx);
        local rows = screen:rows();
        assert.equals(3, #rows);
        assert.equals('Status', rows[1].label);
        assert.equals('Enter group', rows[2].label);
        assert.equals('Leave', rows[3].label);
    end);

    it('queues status and leave directly', function()
        local screen = screens.arena(ctx);
        screen.on_confirm(screen, 1, { push = function() end });
        screen.on_confirm(screen, 3, { push = function() end });
        assert.same({ '!arena', '!arena leave' }, queued);
    end);

    it('enter requires confirm before !arena enter', function()
        local screen = screens.arena(ctx);
        local pushed = nil;
        screen.on_confirm(screen, 2, {
            push = function(_, child)
                pushed = child;
            end,
        });
        assert.is_not_nil(pushed);

        local n = nav.new();
        n:push(pushed);
        n.focus = 2;
        n:confirm();
        assert.same({}, queued);

        n.focus = 1;
        n:confirm();
        assert.same({ '!arena enter' }, queued);
    end);
end);
