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

    it('builds squad send/fetch by item id', function()
        assert.equals('!squad send Bob 4096 5', cmds.squad_send('Bob', 4096, 5));
        assert.equals('!squad fetch Alice 16512 1', cmds.squad_fetch('Alice', 16512, 1));
    end);

    it('builds squad hints', function()
        assert.equals('!squad hints', cmds.squad_hints());
        assert.equals('!squad hints me', cmds.squad_hints('me'));
        assert.equals('!squad hints Yakapo', cmds.squad_hints('Yakapo'));
    end);

    it('builds rules use with quoted set names', function()
        assert.equals('!squad rules use me "My Set"', cmds.rules_use('me', 'My Set'));
        assert.equals('!squad rules use Tea "Preset: WHM" when WHM', cmds.rules_use_when('Tea', 'Preset: WHM', 'WHM'));
    end);

    it('builds dwq box for in-transit items', function()
        assert.equals('!dwq box Yakapo', cmds.dwq_box('Yakapo'));
    end);

    it('builds job cast commands', function()
        assert.equals('!whm cure3 me', cmds.job_cast('whm', 'cure3', 'me'));
        assert.equals('!blm stone', cmds.job_cast('blm', 'stone', nil));
        assert.equals('!allwhm curaga me', cmds.job_cast_all('WHM', 'curaga', 'me'));
        assert.equals('!whm spells', cmds.job_spell_list('whm'));
        assert.equals('!optimizegear preview', cmds.optimizegear_preview());
    end);
end);
