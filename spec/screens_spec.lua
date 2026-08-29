package.path = 'addons/dwhub/?.lua;' .. package.path;

local screens = require('screens');

describe('screens', function()
    it('loads home with five MENU-IA groups', function()
        local home = screens.home(function() end);
        assert.equals('home', home.id);
        assert.equals(5, #home:rows());
    end);

    it('builds squad screen table', function()
        local ctx = { enqueue = function() end, set_status = function() end };
        local squad = screens.squad(ctx);
        assert.equals('squad', squad.id);
        assert.is_true(#squad:rows() > 10);
    end);
end);
