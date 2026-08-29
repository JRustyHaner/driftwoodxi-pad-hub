package.path = 'addons/dwhub/?.lua;' .. package.path;

local data = require('data');

describe('data sender registry', function()
    before_each(function()
        data.reset();
    end);

    it('registers shipped and expansion senders', function()
        local senders = data.known_senders();
        assert.equals('squad', senders['_DWSDATA']);
        assert.equals('bags', senders['_DWDATA']);
        assert.equals('warehouse', senders['_DWUDATA']);
        assert.equals('market', senders['_DWADATA']);
        assert.equals('merc', senders['_DWMDATA']);
        assert.equals('tracker', senders['_DWTDATA']);
        assert.equals('fish', senders['_DWFDATA']);
        assert.equals('scan', senders['_DWXDATA']);
    end);

    it('observes stub envelopes without error', function()
        assert.is_true(data.handle_machine('_DWUDATA', 'd|1|summary'));
        assert.is_true(data.handle_machine('_DWUDATA', 'm|12 slots used.'));
        assert.is_true(data.handle_machine('_DWUDATA', 'z'));
        assert.equals('12 slots used.', data.state().status);
    end);

    it('ignores unknown senders', function()
        assert.is_false(data.handle_machine('_DWZZDATA', 'd|1|noop'));
    end);
end);
