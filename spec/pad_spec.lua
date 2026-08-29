package.path = 'addons/dwhub/?.lua;' .. package.path;

local pad = require('pad');

describe('pad', function()
    it('detects button edges', function()
        assert.is_true(pad.edge_pressed(0x1000, 0, pad.BTN.A));
        assert.is_false(pad.edge_pressed(0x1000, 0x1000, pad.BTN.A));
        assert.is_false(pad.edge_pressed(0, 0, pad.BTN.A));
    end)

    it('clears gamepad from modified state while active', function()
        pad.set_active(true);
        local modified = { Gamepad = { wButtons = 0x1000, sThumbLY = 1000 } };
        pad.on_xinput_state({ state = { Gamepad = { wButtons = 0x1000 } }, state_modified = modified });
        assert.equals(0, modified.Gamepad.wButtons);
        assert.equals(0, modified.Gamepad.sThumbLY);
        pad.set_active(false);
    end)

    it('accepts multi-arg xinput_state callbacks', function()
        pad.set_active(false);
        pad.on_xinput_state(16, 0, { wButtons = 0x0008 }, nil);
        assert.is_true(pad.pressed(pad.BTN.RIGHT));
    end)

    it('accepts flat gamepad tables on state', function()
        pad.set_active(false);
        pad.on_xinput_state({ state = { wButtons = 0x1000 }, state_modified = nil });
        assert.is_true(pad.pressed(pad.BTN.A));
    end)
end);
