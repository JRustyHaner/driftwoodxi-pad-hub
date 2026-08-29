package.path = 'addons/dwhub/?.lua;spec/?.lua;' .. package.path;

local data = require('data');
local fixtures = require('fixture_loader');

local function stub_item_names()
    data.set_item_name_fn(function(id)
        if (id == 4096) then
            return 'Fire Crystal';
        end
        return nil;
    end);
end

describe('data machine parse', function()
    before_each(function()
        data.reset();
        stub_item_names();
    end);

    describe('fixture loader', function()
        it('loads squad_who metadata and lines', function()
            local fx = fixtures.load('squad_who');
            assert.equals('_DWSDATA', fx.meta.sender);
            assert.equals('who', fx.meta.verb);
            assert.equals(4, #fx.lines);
            assert.equals('d|1|who', fx.lines[1]);
        end);
    end);

    describe('squad who fixture', function()
        it('builds account roster from _DWSDATA', function()
            fixtures.apply_machine(data, fixtures.load('squad_who'));
            local labels = data.char_labels({ me = true });
            assert.same({ 'me', 'Alice', 'Bob' }, labels);
            assert.equals(2, #data.squad_slot_rows());
        end);
    end);

    describe('bags find fixture', function()
        it('parses find hits from _DWDATA', function()
            fixtures.apply_machine(data, fixtures.load('bags_find'));
            local finds = data.find_entries();
            assert.equals(1, #finds);
            assert.equals(4096, finds[1].itemid);
            assert.equals('Fire Crystal', finds[1].name);
            assert.equals(12, finds[1].qty);
            assert.equals(0, finds[1].loc);
        end);
    end);

    describe('bags bag fixture', function()
        it('parses container counts and items', function()
            data.state().bag_charid = 10;
            fixtures.apply_machine(data, fixtures.load('bags_bag'));
            local locs = data.bag_locations();
            assert.equals(1, #locs);
            assert.equals('Inventory', locs[1].label);
            assert.equals(2, locs[1].used);
            assert.equals(30, locs[1].size);
            local items = data.bag_items(0);
            assert.equals(1, #items);
            assert.equals('Fire Crystal', items[1].name);
            assert.equals(5, items[1].qty);
        end);
    end);

    describe('jobs list fixture', function()
        it('parses preset names from _DWJDATA list', function()
            fixtures.apply_machine(data, fixtures.load('jobs_list'));
            assert.same({ 'NukerParty', 'TankLine' }, data.job_preset_labels());
        end);
    end);

    describe('jobs who fixture', function()
        it('parses unlock bitmask and job levels', function()
            fixtures.apply_machine(data, fixtures.load('jobs_who'));
            assert.is_true(data.job_unlocked('Alice', 1));
            assert.is_false(data.job_unlocked('Alice', 2));
            assert.equals(1, data.job_level('Alice', 1));
            local rows = data.job_pick_rows('Alice');
            assert.is_false(rows[1].dim);
            assert.is_true(rows[2].dim);
        end);
    end);

    describe('rules list fixture', function()
        it('parses custom rule set names', function()
            fixtures.apply_machine(data, fixtures.load('rules_list'));
            assert.same({ 'MySet' }, data.rule_set_labels());
        end);
    end);

    describe('rules presets fixture', function()
        it('parses shipped preset names', function()
            fixtures.apply_machine(data, fixtures.load('rules_presets'));
            assert.same({ 'Standard' }, data.rule_preset_labels());
        end);
    end);

    describe('warehouse page fixture', function()
        it('parses shelf paging from _DWUDATA', function()
            data.set_item_name_fn(function(id)
                if (id == 4096) then
                    return 'Fire Crystal';
                end
                return nil;
            end);
            fixtures.apply_machine(data, fixtures.load('warehouse_page'));
            local info = data.warehouse_info();
            assert.equals(2, info.page);
            assert.equals(12, info.used);
            assert.equals(2, #data.warehouse_items());
            assert.equals(51, data.warehouse_items()[1].slot);
        end);
    end);

    describe('port list fixture', function()
        it('parses starred and plain destination lines', function()
            fixtures.apply_port(data, fixtures.load('port_list'));
            local dests = data.port_entries();
            assert.equals(2, #dests);
            assert.is_true(dests[1].usable);
            assert.equals('1', dests[1].id);
            assert.is_true(dests[1].label:find('Southern San d\'Oria', 1, true) ~= nil);
            assert.is_false(dests[2].usable);
            assert.equals('2', dests[2].id);
        end);
    end);

    describe('spell list fixture', function()
        it('parses spell names and skips headers', function()
            fixtures.apply_spell(data, fixtures.load('spell_list'));
            assert.same({ 'cure', 'cure2', 'cure3' }, data.spell_labels());
        end);
    end);

    describe('tracker sync fixture', function()
        it('parses active quests and missions from _DWTDATA', function()
            fixtures.apply_machine(data, fixtures.load('tracker_sync'));
            assert.is_true(data.tracker_synced());
            assert.equals('Quest #1012', data.tracker_quest_label(data.tracker_active_quests()[1]));
            assert.equals('Log 0 · step 3 of 12', data.tracker_entry_desc(data.tracker_active_quests()[1]));
            assert.equals(2, #data.tracker_active_quests());
            assert.equals(1, #data.tracker_active_missions());
        end);
    end);

    describe('channel isolation', function()
        it('keeps squad roster when jobs who interleaves', function()
            data.handle_machine('_DWSDATA', 'd|1|who');
            data.handle_machine('_DWJDATA', 'd|1|who');
            data.handle_machine('_DWSDATA', 'c|10|Alice|1|99|0|0|5|0|0|1');
            data.handle_machine('_DWJDATA', 'c|11|Bob|5|50|1|20|1|0|0|0');
            data.handle_machine('_DWSDATA', 'z|');
            assert.same({ 'Alice' }, data.char_labels({ me = false }));
            data.handle_machine('_DWJDATA', 'z|');
            assert.equals('Bob', data.job_member('Bob').name);
        end);
    end);

    describe('squad job tags', function()
        it('builds whm / whm2 tags from roster slots', function()
            data.handle_machine('_DWSDATA', 'd|1|who');
            data.handle_machine('_DWSDATA', 'c|10|Alice|3|99|0|0|5|0|0|1');
            data.handle_machine('_DWSDATA', 'c|11|Bob|3|50|0|0|5|0|0|2');
            data.handle_machine('_DWSDATA', 'z|');
            local tags = data.squad_tag_entries();
            assert.equals(2, #tags);
            assert.equals('whm', tags[1].tag);
            assert.equals('whm2', tags[2].tag);
        end);
    end);
end);
