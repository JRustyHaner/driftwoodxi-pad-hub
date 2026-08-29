package.path = 'addons/dwhub/?.lua;spec/?.lua;' .. package.path;

local data = require('data');
local fixtures = require('fixture_loader');

describe('market fixtures', function()
    before_each(function()
        data.reset();
    end);

    it('parses listings page from _DWADATA', function()
        fixtures.apply_machine(data, fixtures.load('market_page'));
        local info = data.market_listings_info();
        assert.equals(1, info.page);
        assert.equals(3, info.total_pages);
        assert.equals(50, info.total);
        local listings = data.market_listings();
        assert.equals(2, #listings);
        assert.equals('a1042', listings[1].ref);
        assert.equals('Fire Crystal', listings[1].name);
        assert.equals(500, listings[1].price);
        assert.equals(12, listings[1].qty);
    end);

    it('parses buy orders from _DWADATA', function()
        fixtures.apply_machine(data, fixtures.load('market_orders'));
        assert.equals(1, #data.market_orders());
        assert.equals('o501', data.market_orders()[1].ref);
    end);
end);
