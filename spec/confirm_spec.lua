package.path = 'addons/dwhub/?.lua;' .. package.path;

local nav = require('nav');
local H = require('screens._helpers');

describe('confirm_pick', function()
    local function root_screen()
        return {
            id = 'root',
            title = 'Root',
            rows = function()
                return { { label = 'Root row', desc = 'root' } };
            end,
        };
    end

    it('runs on_yes only on Confirm', function()
        local n = nav.new();
        local yes = false;
        n:push(root_screen());
        n:push(H.confirm_pick('Test action', 'Are you sure?', function(nav2)
            yes = true;
            nav2:pop();
        end));
        assert.equals(2, n:depth());
        n.focus = 1;
        n:confirm();
        assert.is_true(yes);
        assert.equals(1, n:depth());
    end);

    it('Cancel confirm does not run on_yes', function()
        local n = nav.new();
        local yes = false;
        n:push(root_screen());
        n:push(H.confirm_pick('Test action', 'Are you sure?', function()
            yes = true;
        end));
        n.focus = 2;
        n:confirm();
        assert.is_false(yes);
        assert.equals(1, n:depth());
    end);

    it('B/back pops confirm without on_yes', function()
        local n = nav.new();
        local yes = false;
        n:push(root_screen());
        n:push(H.confirm_pick('Test action', 'Are you sure?', function()
            yes = true;
        end));
        n:back();
        assert.is_false(yes);
        assert.equals(1, n:depth());
    end);
end);
