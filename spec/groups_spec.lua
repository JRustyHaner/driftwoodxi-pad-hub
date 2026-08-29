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

    it('ships Items and expansion stubs under Inventory and Trade', function()
        local inv = screens.HOME_GROUPS[2];
        assert.equals('Items', inv.categories[1].category);
        assert.equals('Storage', inv.categories[2].category);
        assert.is_nil(inv.categories[2].dim);
        assert.equals('Market', inv.categories[3].category);
        assert.equals('Merc', inv.categories[4].category);
    end);

    it('ships expansion categories in Quests, Instances, and Field groups', function()
        local quests = screens.HOME_GROUPS[3];
        assert.equals('Quests', quests.categories[1].category);
        assert.equals('Drift', quests.categories[2].category);
        assert.equals('Fish', quests.categories[3].category);
        assert.is_true(quests.categories[4].dim);

        local instances = screens.HOME_GROUPS[4];
        assert.equals('Raid', instances.categories[1].category);
        assert.equals('Arena', instances.categories[2].category);

        local field = screens.HOME_GROUPS[5];
        assert.equals('Scan', field.categories[1].category);
        assert.equals('Engage', field.categories[2].category);
    end);
end);
