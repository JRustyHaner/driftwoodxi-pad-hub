package.path = 'addons/dwhub/?.lua;' .. package.path;

local cmds = require('cmds');
local nav = require('nav');
local screens = require('screens');
local data = require('data');
local fixtures = require('fixture_loader');

describe('storage screen', function()
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

    it('builds warehouse commands', function()
        assert.equals('!warehouse', cmds.warehouse_summary());
        assert.equals('!warehouse page 3', cmds.warehouse_page(3));
        assert.equals('!warehouse take 51 Alice', cmds.warehouse_take(51, 'Alice'));
        assert.equals('!warehouse put Alice 0 5 99', cmds.warehouse_put('Alice', 0, 5, 99));
        assert.equals('!warehouse stashall', cmds.warehouse_stashall());
        assert.equals('!warehouse pull:4096,16512', cmds.warehouse_pull('4096,16512'));
        assert.equals('!warehouse pin 51', cmds.warehouse_pin(51));
        assert.equals('!warehouse unpin 51', cmds.warehouse_unpin(51));
        assert.equals('!warehouse buy', cmds.warehouse_buy());
        assert.equals('!warehouse buy confirm', cmds.warehouse_buy_confirm());
        assert.equals('!dwu page 2', cmds.dwu_page(2));
    end);

    it('lists eight storage rows', function()
        local screen = screens.storage(ctx);
        local rows = screen:rows();
        assert.equals(8, #rows);
        assert.equals('Summary', rows[1].label);
        assert.equals('Browse shelf…', rows[2].label);
        assert.equals('Take…', rows[3].label);
        assert.equals('Put from bags…', rows[4].label);
        assert.equals('Stash all…', rows[5].label);
        assert.equals('Pull list…', rows[6].label);
        assert.equals('Pin / Unpin…', rows[7].label);
        assert.equals('Buy slot…', rows[8].label);
    end);

    it('summary row queues !warehouse', function()
        local screen = screens.storage(ctx);
        screen.on_confirm(screen, 1, { push = function() end });
        assert.equals('!warehouse', queued[1]);
    end);

    it('browse flow requests !dwu page', function()
        local screen = screens.storage(ctx);
        local pushed = nil;
        screen.on_confirm(screen, 2, {
            push = function(_, child)
                pushed = child;
            end,
        });
        assert.is_not_nil(pushed);
        assert.same({ '!dwu page 1' }, queued);
    end);

    it('take flow queues !warehouse take after item and character picks', function()
        data.set_item_name_fn(function(id)
            if (id == 4096) then
                return 'Fire Crystal';
            end
            return nil;
        end);
        fixtures.apply_machine(data, fixtures.load('warehouse_page'));
        fixtures.apply_machine(data, fixtures.load('squad_who'));

        local screen = screens.storage(ctx);
        local n = nav.new();
        screen.on_confirm(screen, 3, n);
        assert.is_true(n:depth() >= 1);

        local shelf = n:current();
        local rows = shelf:rows();
        local item_index = nil;
        for i, row in ipairs(rows) do
            if (row.id == 'item') then
                item_index = i;
                break;
            end
        end
        assert.is_not_nil(item_index);
        shelf.on_confirm(shelf, item_index, n);

        local char_pick = n:current();
        local char_rows = char_pick:rows();
        local alice_index = nil;
        for i, row in ipairs(char_rows) do
            if (row.label == 'Alice') then
                alice_index = i;
                break;
            end
        end
        assert.is_not_nil(alice_index);
        char_pick.on_confirm(char_pick, alice_index, n);

        local found = false;
        for _, cmd in ipairs(queued) do
            if (cmd == '!warehouse take 51 Alice') then
                found = true;
                break;
            end
        end
        assert.is_true(found);
    end);

    it('stash all confirm queues !warehouse stashall', function()
        local screen = screens.storage(ctx);
        local n = nav.new();
        screen.on_confirm(screen, 5, n);
        local confirm = n:current();
        confirm.on_confirm(confirm, 1, n);
        assert.same({ '!warehouse stashall' }, queued);
    end);

    it('buy slot confirm queues buy then buy confirm', function()
        local screen = screens.storage(ctx);
        local n = nav.new();
        screen.on_confirm(screen, 8, n);
        local confirm = n:current();
        confirm.on_confirm(confirm, 1, n);
        assert.equals('!warehouse buy', queued[1]);
        assert.equals('!warehouse buy confirm', queued[2]);
    end);
end);
