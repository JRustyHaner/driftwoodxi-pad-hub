package.path = 'addons/dwhub/?.lua;' .. package.path;

local queue = require('queue');

describe('queue', function()
    it('preserves order', function()
        local sent = {};
        local q = queue.new({
            send_fn = function(c) sent[#sent + 1] = c; end,
            clock_fn = function() return 100; end,
            interval = 1.0,
        });
        q:enqueue('!a');
        q:enqueue('!b');
        assert.equals(2, q:len());
        assert.equals('!a', q:tick());
        -- same clock: blocked by interval
        assert.is_nil(q:tick());
        assert.equals(1, q:len());
    end);

    it('dedupes identical pending commands', function()
        local q = queue.new({
            send_fn = function() end,
            clock_fn = function() return 0; end,
        });
        assert.is_true(q:enqueue('!squad call'));
        assert.is_false(q:enqueue('!squad call'));
        assert.equals(1, q:len());
    end);

    it('respects throttle spacing', function()
        local t = 0;
        local sent = {};
        local q = queue.new({
            send_fn = function(c) sent[#sent + 1] = c; end,
            clock_fn = function() return t; end,
            interval = 1.2,
        });
        q:enqueue('!one');
        q:enqueue('!two');
        assert.equals('!one', q:tick());
        t = 0.5;
        assert.is_nil(q:tick());
        t = 1.2;
        assert.equals('!two', q:tick());
        assert.same({ '!one', '!two' }, sent);
    end);

    it('clear empties pending work', function()
        local q = queue.new({
            send_fn = function() end,
            clock_fn = function() return 0; end,
        });
        q:enqueue('!x');
        q:enqueue('!y');
        q:clear();
        assert.equals(0, q:len());
        assert.is_nil(q:tick());
    end);
end);
