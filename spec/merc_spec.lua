package.path = 'addons/dwhub/?.lua;spec/?.lua;' .. package.path;

local data = require('data');
local fixtures = require('fixture_loader');

describe('merc board fixture', function()
    before_each(function()
        data.reset();
    end);

    it('parses board listings from _DWMDATA', function()
        fixtures.apply_machine(data, fixtures.load('merc_board'));
        local info = data.merc_board_info();
        assert.equals(1, info.page);
        assert.equals(2, info.total_pages);
        assert.equals(10, info.total);

        local entries = data.merc_board_entries();
        assert.equals(2, #entries);
        assert.equals('m101', entries[1].ref);
        assert.equals('Alice', entries[1].name);
        assert.equals('WAR', entries[1].job);
        assert.equals(75, entries[1].level);
        assert.equals(5000, entries[1].price);
    end);
end);
