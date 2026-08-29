package.path = 'addons/dwhub/?.lua;spec/?.lua;' .. package.path;

local data = require('data');
local fixtures = require('fixture_loader');
local screens = require('screens');

describe('quests screen', function()
    before_each(function()
        data.reset();
    end);

    it('lists refresh and browse rows per #50', function()
        local ctx = { enqueue = function() end, set_status = function() end };
        local screen = screens.quests(ctx);
        local rows = screen:rows();
        assert.equals(3, #rows);
        assert.equals('Refresh journal', rows[1].label);
        assert.equals('Quest list…', rows[2].label);
        assert.equals('Mission list…', rows[3].label);
    end);

    it('shows parsed active quests after sync fixture', function()
        fixtures.apply_machine(data, fixtures.load('tracker_sync'));
        assert.is_true(data.tracker_synced());
        local quests = data.tracker_active_quests();
        assert.equals(2, #quests);
        assert.equals(1012, quests[1].id);
        assert.equals(3, quests[1].step);
        assert.equals(12, quests[1].n);

        local missions = data.tracker_active_missions();
        assert.equals(1, #missions);
        assert.equals(200, missions[1].id);
        assert.equals(2, missions[1].step);
    end);
end);
