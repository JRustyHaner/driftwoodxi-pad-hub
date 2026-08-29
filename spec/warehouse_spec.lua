package.path = 'addons/dwhub/?.lua;spec/?.lua;' .. package.path;

local data = require('data');
local fixtures = require('fixture_loader');

describe('warehouse page fixture', function()
    before_each(function()
        data.reset();
        data.set_item_name_fn(function(id)
            if (id == 4096) then
                return 'Fire Crystal';
            end
            if (id == 16512) then
                return 'Hi-Potion';
            end
            return nil;
        end);
    end);

    it('parses shelf items and paging from _DWUDATA', function()
        fixtures.apply_machine(data, fixtures.load('warehouse_page'));
        local info = data.warehouse_info();
        assert.equals(2, info.page);
        assert.equals(20, info.total_pages);
        assert.equals(12, info.used);
        assert.equals(1000, info.capacity);
        assert.equals(50, info.page_size);

        local items = data.warehouse_items();
        assert.equals(2, #items);
        assert.equals(51, items[1].slot);
        assert.equals('Fire Crystal', items[1].name);
        assert.equals(5, items[1].qty);
        assert.equals(52, items[2].slot);
        assert.equals('Hi-Potion', items[2].name);
    end);
end);
