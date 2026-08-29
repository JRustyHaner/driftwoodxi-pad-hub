package.path = 'addons/dwhub/?.lua;spec/?.lua;' .. package.path;

local cmds = require('cmds');
local nav = require('nav');
local screens = require('screens');
local data = require('data');
local fixtures = require('fixture_loader');

describe('market screen', function()
    local queued = {};
    local ctx = {
        enqueue = function(command)
            queued[#queued + 1] = command;
        end,
        set_status = function() end,
    };

    before_each(function()
        queued = {};
        data.reset();
    end);

    it('builds market commands', function()
        assert.equals('!market', cmds.market_summary());
        assert.equals('!market page 2', cmds.market_page(2));
        assert.equals('!dwa page 1', cmds.dwa_page(1));
        assert.equals('!market sell Fire Crystal', cmds.market_sell('Fire Crystal'));
        assert.equals('!market buy a1042', cmds.market_buy('a1042'));
        assert.equals('!market cancel a1042', cmds.market_cancel('a1042'));
        assert.equals('!market order 10 Fire Crystal', cmds.market_order(10, 'Fire Crystal'));
        assert.equals('!market fill 5 o501', cmds.market_fill('o501', 5));
        assert.equals('!market cancelorder o501', cmds.market_cancelorder('o501'));
    end);

    it('lists eleven market rows', function()
        local screen = screens.market(ctx);
        assert.equals(11, #screen:rows());
    end);

    it('browse requests !dwa page 1', function()
        local screen = screens.market(ctx);
        screen.on_confirm(screen, 2, { push = function() end });
        assert.equals('!dwa page 1', queued[1]);
    end);

    it('buy by ref queues !market buy', function()
        fixtures.apply_machine(data, fixtures.load('market_page'));
        local screen = screens.market(ctx);
        local n = nav.new();
        screen.on_confirm(screen, 7, n);
        n:current().on_confirm(n:current(), 2, n);
        local entry = n:current();
        entry.search[1] = 'a1042';
        entry.on_confirm(entry, 1, n);
        assert.equals('!market buy a1042', queued[#queued]);
    end);
end);
