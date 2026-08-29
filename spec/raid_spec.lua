package.path = 'addons/dwhub/?.lua;' .. package.path;

local cmds = require('cmds');
local nav = require('nav');
local screens = require('screens');

describe('raid screen', function()
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

    it('defines eight bosses and four tiers', function()
        assert.equals(8, #cmds.RAID_BOSSES);
        assert.equals(4, #cmds.RAID_TIERS);
        assert.equals('tidebound', cmds.RAID_BOSSES[1]);
        assert.equals('savage', cmds.RAID_TIERS[4]);
    end);

    it('builds raid commands', function()
        assert.equals('!raid', cmds.raid_board());
        assert.equals('!raid enter tidebound easy', cmds.raid_enter('tidebound', 'easy'));
        assert.equals('!raid leave', cmds.raid_leave());
        assert.equals('!raid marks', cmds.raid_marks());
        assert.equals('!raid shop supplies', cmds.raid_shop('supplies'));
        assert.equals('!raid buy 21', cmds.raid_buy('21'));
        assert.equals('!raid confirm', cmds.raid_confirm());
        assert.equals('!raid reforge', cmds.raid_reforge());
    end);

    it('lists six raid rows per #49 and #58', function()
        local screen = screens.raid(ctx);
        local rows = screen:rows();
        assert.equals(6, #rows);
        assert.equals('Board', rows[1].label);
        assert.equals('Enter trial…', rows[2].label);
        assert.equals('Leave', rows[3].label);
        assert.equals('Driftmarks', rows[4].label);
        assert.equals('Shop…', rows[5].label);
        assert.equals('Reforge', rows[6].label);
    end);

    it('queues board, leave, marks, and reforge directly', function()
        local screen = screens.raid(ctx);
        screen.on_confirm(screen, 1, { push = function() end });
        screen.on_confirm(screen, 3, { push = function() end });
        screen.on_confirm(screen, 4, { push = function() end });
        screen.on_confirm(screen, 6, { push = function() end });
        assert.same({ '!raid', '!raid leave', '!raid marks', '!raid reforge' }, queued);
    end);

    it('shop buy flow queues buy then confirm', function()
        local screen = screens.raid(ctx);
        local n = nav.new();
        screen.on_confirm(screen, 5, n);
        n:current().on_confirm(n:current(), 1, n);
        local entry = n:current();
        entry.search[1] = '21';
        entry.on_confirm(entry, 1, n);
        local confirm = n:current();
        confirm.on_confirm(confirm, 1, n);
        assert.equals('!raid shop supplies', queued[1]);
        assert.equals('!raid buy 21', queued[2]);
        assert.equals('!raid confirm', queued[3]);
    end);

    it('enter flow picks boss, tier, and confirm', function()
        local screen = screens.raid(ctx);
        local pushed = nil;
        screen.on_confirm(screen, 2, {
            push = function(_, child)
                pushed = child;
            end,
        });
        assert.is_not_nil(pushed);

        local n = nav.new();
        n:push(pushed);
        n.focus = 1;
        n:confirm();
        assert.equals(2, n:depth());

        n:confirm();
        assert.equals(3, n:depth());

        n.focus = 2;
        n:confirm();
        assert.same({}, queued);

        n.focus = 1;
        n:confirm();
        assert.same({ '!raid enter tidebound normal' }, queued);
    end);
end);
