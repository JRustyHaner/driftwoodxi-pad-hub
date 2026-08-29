package.path = 'addons/dwhub/?.lua;' .. package.path;

local cmds = require('cmds');
local nav = require('nav');
local screens = require('screens');

describe('engage screen', function()
    local ctx = {
        queued = {},
        enqueue = function(command)
            ctx.queued[#ctx.queued + 1] = command;
        end,
        set_status = function() end,
    };

    it('builds dwengage slash commands', function()
        assert.equals('/dwengage on', cmds.dwengage_on());
        assert.equals('/dwengage off', cmds.dwengage_off());
    end);

    it('lists four engage rows per #45', function()
        local screen = screens.engage(ctx);
        local rows = screen:rows();
        assert.equals(4, #rows);
        assert.equals('Auto-target next mob', rows[1].label);
        assert.equals('Trust engage: Retail', rows[2].label);
        assert.equals('Trust engage: Attack', rows[3].label);
        assert.equals('Show trust setting', rows[4].label);
    end);

    it('queues trustengage modes from main screen', function()
        local screen = screens.engage(ctx);
        ctx.queued = {};
        screen.on_confirm(screen, 2, { status = '', push = function() end });
        assert.same({ '!trustengage 0' }, ctx.queued);
        screen.on_confirm(screen, 3, { status = '', push = function() end });
        assert.same({ '!trustengage 0', '!trustengage 1' }, ctx.queued);
        screen.on_confirm(screen, 4, { status = '', push = function() end });
        assert.same({ '!trustengage 0', '!trustengage 1', '!trustengage' }, ctx.queued);
    end);

    it('auto-target pick queues /dwengage on or off', function()
        local screen = screens.engage(ctx);
        local pushed = nil;
        local n = {
            status = '',
            push = function(_, child)
                pushed = child;
            end,
        };
        ctx.queued = {};
        screen.on_confirm(screen, 1, n);
        assert.is_not_nil(pushed);

        local nav_stack = nav.new();
        nav_stack:push(pushed);
        nav_stack.focus = 1;
        nav_stack:confirm();
        assert.same({ '/dwengage on' }, ctx.queued);

        ctx.queued = {};
        nav_stack.focus = 2;
        nav_stack:confirm();
        assert.same({ '/dwengage off' }, ctx.queued);
    end);
end);
