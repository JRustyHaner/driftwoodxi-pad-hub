package.path = 'addons/dwhub/?.lua;' .. package.path;

local cmds = require('cmds');
local nav = require('nav');
local screens = require('screens');

describe('drift screen', function()
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

    it('defines eight contract slots', function()
        assert.equals(8, #cmds.DRIFT_SLOTS);
        assert.equals('d4', cmds.DRIFT_SLOTS[4]);
        assert.equals('w4', cmds.DRIFT_SLOTS[8]);
    end);

    it('builds drift commands', function()
        assert.equals('!drift', cmds.drift_board());
        assert.equals('!drift balance', cmds.drift_balance());
        assert.equals('!drift accept d1', cmds.drift_accept('d1'));
        assert.equals('!drift abandon w2', cmds.drift_abandon('w2'));
        assert.equals('!drift augments', cmds.drift_augments());
        assert.equals('!drift augment x2', cmds.drift_augment_price('x2'));
        assert.equals('!drift confirm', cmds.drift_confirm());
        assert.equals('!drift shelf war', cmds.drift_shelf('WAR'));
        assert.equals('!drift buy 21', cmds.drift_buy(21));
    end);

    it('lists five drift rows per #51 and #52', function()
        local screen = screens.drift(ctx);
        local rows = screen:rows();
        assert.equals(5, #rows);
        assert.equals('Board', rows[1].label);
        assert.equals('Accept / abandon…', rows[2].label);
        assert.equals('Balance', rows[3].label);
        assert.equals('Augments…', rows[4].label);
        assert.equals('Outfitter…', rows[5].label);
    end);

    it('accept flow queues !drift accept', function()
        local screen = screens.drift(ctx);
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
        n.focus = 1;
        n:confirm();
        assert.same({ '!drift accept d1' }, queued);
    end);

    it('abandon flow requires confirm', function()
        local screen = screens.drift(ctx);
        local pushed = nil;
        screen.on_confirm(screen, 2, {
            push = function(_, child)
                pushed = child;
            end,
        });
        local n = nav.new();
        n:push(pushed);
        n.focus = 2;
        n:confirm();
        n.focus = 2;
        n:confirm();
        assert.same({}, queued);
        n.focus = 1;
        n:confirm();
        assert.same({ '!drift abandon d2' }, queued);
    end);

    it('augment buy prices then confirms', function()
        local screen = screens.drift(ctx);
        local pushed = nil;
        screen.on_confirm(screen, 4, {
            push = function(_, child)
                pushed = child;
            end,
        });
        local n = nav.new();
        n:push(pushed);
        n.focus = 2;
        n:confirm();
        n.focus = 1;
        n:confirm();
        assert.same({ '!drift augment x1' }, queued);
        n.focus = 1;
        n:confirm();
        assert.same({ '!drift augment x1', '!drift confirm' }, queued);
    end);

    it('outfitter shelves job then buy confirms', function()
        local screen = screens.drift(ctx);
        local pushed = nil;
        screen.on_confirm(screen, 5, {
            push = function(_, child)
                pushed = child;
            end,
        });
        local n = nav.new();
        n:push(pushed);
        n.focus = 1;
        n:confirm();
        assert.same({ '!drift shelf war' }, queued);
        local buy_screen = n:current();
        buy_screen.search[1] = '21';
        buy_screen.on_confirm(buy_screen, 1, n);
        assert.same({ '!drift shelf war', '!drift buy 21' }, queued);
        n.focus = 1;
        n:confirm();
        assert.same({ '!drift shelf war', '!drift buy 21', '!drift confirm' }, queued);
    end);
end);
