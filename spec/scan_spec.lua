package.path = 'addons/dwhub/?.lua;' .. package.path;

local cmds = require('cmds');
local nav = require('nav');
local scan_mod = require('screens.scan');
local screens = require('screens');

describe('scan screen', function()
    local status = '';
    local queued = {};
    local ctx = {
        enqueue = function(command)
            queued[#queued + 1] = command;
        end,
        set_status = function(msg)
            status = msg or '';
        end,
    };

    before_each(function()
        status = '';
        queued = {};
    end);

    it('lists scan rows per #46', function()
        local screen = screens.scan(ctx);
        local rows = screen:rows();
        assert.equals(2, #rows);
        assert.equals('Scan target', rows[1].label);
        assert.equals('Scan with TH tier…', rows[2].label);
    end);

    it('queues !scan when a target is present', function()
        local screen = screens.scan(ctx);
        local original = scan_mod.has_target;
        scan_mod.has_target = function()
            return true;
        end
        screen.on_confirm(screen, 1, { push = function() end });
        scan_mod.has_target = original;
        assert.same({ '!scan' }, queued);
    end);

    it('sets status when no target on scan', function()
        local screen = screens.scan(ctx);
        local original = scan_mod.has_target;
        scan_mod.has_target = function()
            return false;
        end
        screen.on_confirm(screen, 1, { push = function() end });
        scan_mod.has_target = original;
        assert.same({}, queued);
        assert.is_true(status:find('<t>') ~= nil);
    end);

    it('TH tier pick queues !scan 0 N', function()
        local screen = screens.scan(ctx);
        local original = scan_mod.has_target;
        scan_mod.has_target = function()
            return true;
        end
        local pushed = nil;
        screen.on_confirm(screen, 2, {
            push = function(_, child)
                pushed = child;
            end,
        });
        assert.is_not_nil(pushed);

        local n = nav.new();
        n:push(pushed);
        n.focus = 9;
        n:confirm();
        assert.equals('!scan 0 8', queued[1]);

        queued = {};
        n.focus = 1;
        n:confirm();
        assert.equals('!scan 0 0', queued[1]);
        scan_mod.has_target = original;
    end);

    it('builds scan commands for tiers 0–8', function()
        assert.equals('!scan', cmds.scan_target());
        assert.equals('!scan 0 0', cmds.scan_target(0));
        assert.equals('!scan 0 8', cmds.scan_target(8));
    end);
end);
