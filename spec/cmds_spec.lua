package.path = 'addons/dwhub/?.lua;' .. package.path;

local cmds = require('cmds');

describe('cmds', function()
    it('builds squad call/dismiss', function()
        assert.equals('!squad call', cmds.squad_call());
        assert.equals('!squad dismiss', cmds.squad_dismiss());
    end);

    it('builds jobs set with sub none', function()
        assert.equals('!jobs set me WAR none', cmds.jobs_set('me', 'WAR', 'none'));
        assert.equals('!jobs set Tea WHM BLM', cmds.jobs_set('Tea', 'WHM', 'BLM'));
    end);

    it('builds port go', function()
        assert.equals('!port go hp bastok markets', cmds.port_go('hp', 'bastok markets'));
    end);

    it('builds equip', function()
        assert.equals('!squad equip Yakapo main auto', cmds.squad_equip('Yakapo', 'main', 'auto'));
    end);
end);
