package.path = 'addons/dwhub/?.lua;' .. package.path;

local screens = require('screens');

describe('HOME_GROUPS menu IA', function()
    it('has exactly five Home rows', function()
        assert.equals(5, #screens.HOME_GROUPS);
    end);

    it('uses MENU-IA group labels', function()
        local labels = {};
        for _, g in ipairs(screens.HOME_GROUPS) do
            labels[#labels + 1] = g.label;
        end
        assert.same({
            'Party and Travel',
            'Inventory and Trade',
            'Quests and Crafts',
            'Instances',
            'Field',
        }, labels);
    end);

    it('ships Party and Travel categories', function()
        local party = screens.HOME_GROUPS[1];
        assert.equals('party', party.id);
        assert.equals(4, #party.categories);
        assert.equals('Squad', party.categories[1].category);
        assert.equals('Port', party.categories[4].category);
    end);

    it('ships Items under Inventory and Trade', function()
        local inv = screens.HOME_GROUPS[2];
        assert.equals('Items', inv.categories[1].category);
        assert.is_true(inv.categories[2].dim);
    end);
end);
