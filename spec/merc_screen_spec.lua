package.path = 'addons/dwhub/?.lua;spec/?.lua;' .. package.path;

local cmds = require('cmds');
local nav = require('nav');
local screens = require('screens');
local data = require('data');
local fixtures = require('fixture_loader');

describe('merc screen', function()
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

    it('builds merc commands', function()
        assert.equals('!merc board', cmds.merc_board());
        assert.equals('!merc board WAR 2', cmds.merc_board('WAR', 2));
        assert.equals('!dwm board WHM 1', cmds.dwm_board('WHM', 1));
        assert.equals('!merc quote m101', cmds.merc_quote('m101'));
        assert.equals('!merc hire m101', cmds.merc_hire('m101'));
        assert.equals('!merc call', cmds.merc_call());
        assert.equals('!merc call tank', cmds.merc_call('tank'));
        assert.equals('!merc dismiss', cmds.merc_dismiss());
        assert.equals('!merc list', cmds.merc_list());
        assert.equals('!merc unlist', cmds.merc_unlist());
        assert.equals('!merc earnings', cmds.merc_earnings());
        assert.equals('!merc claim', cmds.merc_claim());
    end);

    it('lists eight merc rows', function()
        local screen = screens.merc(ctx);
        local rows = screen:rows();
        assert.equals(8, #rows);
        assert.equals('Board…', rows[1].label);
        assert.equals('Hire…', rows[2].label);
        assert.equals('Dismiss', rows[4].label);
        assert.equals('Claim', rows[8].label);
    end);

    it('dismiss row queues !merc dismiss', function()
        local screen = screens.merc(ctx);
        screen.on_confirm(screen, 4, { push = function() end });
        assert.equals('!merc dismiss', queued[1]);
    end);

    it('hire flow queues quote then hire after double confirm', function()
        fixtures.apply_machine(data, fixtures.load('merc_board'));

        local screen = screens.merc(ctx);
        local n = nav.new();
        screen.on_confirm(screen, 2, n);

        local hire_menu = n:current();
        hire_menu.on_confirm(hire_menu, 1, n);

        local job_pick = n:current();
        job_pick.on_confirm(job_pick, 1, n);

        local board = n:current();
        local rows = board:rows();
        local entry_index = nil;
        for i, row in ipairs(rows) do
            if (row.id == 'entry') then
                entry_index = i;
                break;
            end
        end
        assert.is_not_nil(entry_index);
        board.on_confirm(board, entry_index, n);

        local confirm1 = n:current();
        confirm1.on_confirm(confirm1, 1, n);

        local confirm2 = n:current();
        confirm2.on_confirm(confirm2, 1, n);

        assert.equals('!merc quote m101', queued[1]);
        assert.equals('!merc hire m101', queued[2]);
    end);
end);
