package.path = 'addons/dwhub/?.lua;' .. package.path;

local data = require('data');

describe('data machine parse', function()
    before_each(function()
        data.reset();
        data.set_item_name_fn(function(id)
            if (id == 4096) then
                return 'Fire Crystal';
            end
            return nil;
        end);
    end);

    it('builds roster from _DWSDATA who envelope', function()
        data.handle_machine('_DWSDATA', 'd|1|who');
        data.handle_machine('_DWSDATA', 'c|10|Alice|1|99|0|0|5|0|0|0|1');
        data.handle_machine('_DWSDATA', 'c|11|Bob|5|50|1|20|1|0|0|0|0');
        data.handle_machine('_DWSDATA', 'z|');
        local labels = data.char_labels({ me = true });
        assert.equals('me', labels[1]);
        assert.equals('Alice', labels[2]);
        assert.equals('Bob', labels[3]);
    end);

    it('parses find hits from _DWDATA', function()
        data.handle_machine('_DWDATA', 'd|1|find');
        data.handle_machine('_DWDATA', 'f|10|0|3:4096:12:0');
        data.handle_machine('_DWDATA', 'z|');
        local finds = data.find_entries();
        assert.equals(1, #finds);
        assert.equals(4096, finds[1].itemid);
        assert.equals('Fire Crystal', finds[1].name);
        assert.equals(12, finds[1].qty);
    end);

    it('parses job presets from _DWJDATA', function()
        data.handle_machine('_DWJDATA', 'd|1|list');
        data.handle_machine('_DWJDATA', 'p|NukerParty|3');
        data.handle_machine('_DWJDATA', 'p|TankLine|2');
        data.handle_machine('_DWJDATA', 'z|');
        local presets = data.job_preset_labels();
        assert.equals(2, #presets);
        assert.equals('NukerParty', presets[1]);
    end);

    it('parses rule sets and presets from _DWGDATA', function()
        data.handle_machine('_DWGDATA', 'd|1|list');
        data.handle_machine('_DWGDATA', 's|1|MySet|4|2|1|0|127|0|0');
        data.handle_machine('_DWGDATA', 'z|');
        data.handle_machine('_DWGDATA', 'd|1|presets');
        data.handle_machine('_DWGDATA', 'p|Standard|9|3|tanky');
        data.handle_machine('_DWGDATA', 'z|');
        assert.same({ 'MySet' }, data.rule_set_labels());
        assert.same({ 'Standard' }, data.rule_preset_labels());
    end);

    it('parses starred port list lines', function()
        data.begin_port_list('hp');
        assert.is_true(data.handle_port_line('* 1 Southern San d\'Oria'));
        assert.is_true(data.handle_port_line('2. Bastok Mines'));
        local dests = data.port_entries();
        assert.equals(2, #dests);
        assert.is_true(dests[1].usable);
        assert.equals('1', dests[1].id);
        assert.is_false(dests[2].usable);
    end);

    it('parses bag containers and items from _DWDATA', function()
        data.state().bag_charid = 10;
        data.handle_machine('_DWDATA', 'd|1|bag');
        data.handle_machine('_DWDATA', 'n|10|0|2|30');
        data.handle_machine('_DWDATA', 'i|10|0|1:4096:5:0');
        data.handle_machine('_DWDATA', 'z|');
        local locs = data.bag_locations();
        assert.equals(1, #locs);
        assert.equals('Inventory', locs[1].label);
        assert.equals(1, #data.bag_items(0));
        assert.equals('Fire Crystal', data.bag_items(0)[1].name);
    end);

    it('keeps squad roster when jobs who interleaves', function()
        data.handle_machine('_DWSDATA', 'd|1|who');
        data.handle_machine('_DWJDATA', 'd|1|who');
        data.handle_machine('_DWSDATA', 'c|10|Alice|1|99|0|0|5|0|0|1');
        data.handle_machine('_DWJDATA', 'c|11|Bob|5|50|1|20|1|0|0|0');
        data.handle_machine('_DWSDATA', 'z|');
        local labels = data.char_labels();
        assert.equals(1, #labels);
        assert.equals('Alice', labels[1]);
        data.handle_machine('_DWJDATA', 'z|');
        assert.equals('Bob', data.job_member('Bob').name);
        assert.equals(0, #data.char_labels({ me = false }));
    end);

    it('greys locked jobs from unlock bitmask', function()
        data.handle_machine('_DWJDATA', 'd|1|who');
        data.handle_machine('_DWJDATA', 'c|10|Alice|1|99|0|0|5|0|1|0');
        data.handle_machine('_DWJDATA', 'j|10|1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,');
        data.handle_machine('_DWJDATA', 'z|');
        assert.is_true(data.job_unlocked('Alice', 1));
        assert.is_false(data.job_unlocked('Alice', 2));
        local rows = data.job_pick_rows('Alice');
        assert.is_false(rows[1].dim);
        assert.is_true(rows[2].dim);
    end);

    it('builds squad job tags from roster slots', function()
        data.handle_machine('_DWSDATA', 'd|1|who');
        data.handle_machine('_DWSDATA', 'c|10|Alice|3|99|0|0|5|0|0|1');
        data.handle_machine('_DWSDATA', 'c|11|Bob|3|50|0|0|5|0|0|2');
        data.handle_machine('_DWSDATA', 'z|');
        local tags = data.squad_tag_entries();
        assert.equals(2, #tags);
        assert.equals('whm', tags[1].tag);
        assert.equals('whm2', tags[2].tag);
    end);

    it('parses spell names from chat lines', function()
        data.begin_spell_list('whm');
        assert.is_true(data.handle_spell_line('cure'));
        assert.is_true(data.handle_spell_line('  2. cure2'));
        assert.is_true(data.handle_spell_line('* cure3'));
        assert.equals(3, #data.spell_labels());
    end);
end);
