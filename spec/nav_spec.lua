package.path = 'addons/dwhub/?.lua;' .. package.path;

local nav = require('nav');

describe('nav', function()
    local function screen(labels)
        return {
            title = 't',
            rows = function()
                local r = {};
                for i, lab in ipairs(labels) do
                    r[i] = { label = lab, desc = 'd:' .. lab };
                end
                return r;
            end,
            on_confirm = function(self, index, n)
                n.status = self:rows()[index].label;
            end,
        };
    end

    it('moves focus with wrap', function()
        local n = nav.new();
        n:push(screen({ 'a', 'b', 'c' }));
        assert.equals(1, n.focus);
        n:move(1);
        assert.equals(2, n.focus);
        n:move(1);
        n:move(1);
        assert.equals(1, n.focus);
        n:move(-1);
        assert.equals(3, n.focus);
    end);

    it('confirm calls screen handler', function()
        local n = nav.new();
        n:push(screen({ 'Squad', 'Jobs' }));
        n:move(1);
        n:confirm();
        assert.equals('Jobs', n.status);
    end);

    it('pop refuses to remove root', function()
        local n = nav.new();
        n:push(screen({ 'x' }));
        assert.is_false(n:pop());
        assert.equals(1, n:depth());
    end);
end);
