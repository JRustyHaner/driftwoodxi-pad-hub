package.path = 'addons/dwhub/?.lua;' .. package.path;

local scale = require('scale');

describe('scale', function()
    it('returns 1.0 at the design resolution', function()
        assert.equals(1.0, scale.from_display(1280, 720));
    end)

    it('scales up for 1080p', function()
        assert.equals(1.5, scale.from_display(1920, 1080));
    end)

    it('scales up for 4K', function()
        assert.equals(3.0, scale.from_display(3840, 2160));
    end)

    it('uses the smaller axis ratio on ultrawide', function()
        assert.equals(1.0, scale.from_display(2560, 720));
    end)

    it('clamps tiny displays', function()
        assert.equals(scale.MIN_SCALE, scale.from_display(640, 360));
    end)

    it('sizes the window proportionally', function()
        local sz = scale.window_size(2.0);
        assert.equals(1040, sz[1]);
        assert.equals(800, sz[2]);
    end)
end);
