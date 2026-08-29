--[[
* Command string builders for hub actions (pure; unit-tested).
--]]

local M = {};

M.JOBS = {
    'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK',
    'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU',
    'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN',
};

M.EQUIP_SLOTS = {
    'main', 'sub', 'ranged', 'ammo', 'head', 'body', 'hands', 'legs',
    'feet', 'neck', 'waist', 'ear1', 'ear2', 'ring1', 'ring2', 'back',
};

M.BEHAVIORS = { 'aggressive', 'defensive', 'passive', 'off' };

function M.squad_call()
    return '!squad call';
end

function M.squad_dismiss()
    return '!squad dismiss';
end

function M.squad_list()
    return '!squad list';
end

function M.squad_set(slot, name)
    return string.format('!squad set %d %s', slot, name);
end

function M.squad_clear(slot)
    return string.format('!squad clear %d', slot);
end

function M.squad_engage()
    return '!squad engage';
end

function M.squad_disengage()
    return '!squad disengage';
end

function M.squad_come()
    return '!squad come';
end

function M.squad_rest()
    return '!squad rest';
end

function M.squad_behavior(profile)
    return string.format('!squad behavior %s', profile);
end

function M.jobs_set(char, main, sub)
    if (sub == nil or sub == '' or sub == 'none') then
        return string.format('!jobs set %s %s none', char, main);
    end
    return string.format('!jobs set %s %s %s', char, main, sub);
end

function M.jobs_use(name)
    return string.format('!jobs use %s', name);
end

function M.jobs_save(name)
    return string.format('!jobs save %s', name);
end

function M.jobs_delete(name)
    return string.format('!jobs delete %s', name);
end

function M.jobs_list()
    return '!jobs list';
end

function M.rules_status()
    return '!squad rules';
end

local function quote_rules_name(name)
    if (name == nil or name == '') then
        return '""';
    end
    return string.format('"%s"', (name:gsub('"', '\\"')));
end

function M.rules_use(member, setname)
    return string.format('!squad rules use %s %s', member, quote_rules_name(setname));
end

function M.rules_use_when(member, setname, job)
    return string.format('!squad rules use %s %s when %s', member, quote_rules_name(setname), job);
end

function M.rules_presets()
    return '!squad rules presets';
end

function M.port_home()
    return '!port home';
end

function M.port_list(tab, page)
    if (page ~= nil) then
        return string.format('!port list %s %d', tab, page);
    end
    return string.format('!port list %s', tab);
end

function M.port_go(tab, dest)
    return string.format('!port go %s %s', tab, dest);
end

function M.port_name(name)
    return string.format('!port %s', name);
end

function M.squad_who()
    return '!squad who';
end

function M.squad_find(text)
    return string.format('!squad find %s', text);
end

function M.squad_send(char, itemid, qty)
    qty = qty or 1;
    return string.format('!squad send %s %d %d', char, itemid, qty);
end

function M.squad_fetch(char, itemid, qty)
    qty = qty or 1;
    return string.format('!squad fetch %s %d %d', char, itemid, qty);
end

--- In-transit / delivery box for one character (dwbags uses !dwq box).
function M.dwq_box(char)
    return string.format('!dwq box %s', char);
end

function M.squad_gear(char)
    return string.format('!squad gear %s', char);
end

function M.squad_equip(char, slot, item)
    return string.format('!squad equip %s %s %s', char, slot, item);
end

function M.squad_hints(char)
    if (char == nil or char == '') then
        return '!squad hints';
    end
    return string.format('!squad hints %s', char);
end

function M.optimizegear()
    return '!optimizegear';
end

function M.optimizegear_preview()
    return '!optimizegear preview';
end

--- Lowercase job-tag abbreviations indexed by FFXI job id (matches cmds.JOBS order).
M.JOB_TAGS = {
    'war', 'mnk', 'whm', 'blm', 'rdm', 'thf', 'pld', 'drk',
    'bst', 'brd', 'rng', 'sam', 'nin', 'drg', 'smn', 'blu',
    'cor', 'pup', 'dnc', 'sch', 'geo', 'run',
};

function M.job_tag_for_id(job_id)
    return M.JOB_TAGS[job_id];
end

function M.job_id_for_tag(tag)
    if (tag == nil) then
        return nil;
    end
    local base = string.match(string.lower(tag), '^(%a+)');
    if (base == nil) then
        return nil;
    end
    for i, abbrev in ipairs(M.JOB_TAGS) do
        if (abbrev == base) then
            return i;
        end
    end
    return nil;
end

--- Cast from one squad member tag: !whm cure3 me
function M.job_cast(tag, spell, target)
    tag = string.lower(tag or '');
    spell = spell or '';
    if (tag == '' or spell == '') then
        return nil;
    end
    if (target == nil or target == '') then
        return string.format('!%s %s', tag, spell);
    end
    return string.format('!%s %s %s', tag, spell, target);
end

--- Cast from every member of a job (main or sub): !allwhm curaga me
function M.job_cast_all(job_upper, spell, target)
    if (job_upper == nil or spell == nil or spell == '') then
        return nil;
    end
    local tag = 'all' .. string.lower(job_upper);
    if (target == nil or target == '') then
        return string.format('!%s %s', tag, spell);
    end
    return string.format('!%s %s %s', tag, spell, target);
end

function M.job_spell_list(tag)
    tag = string.lower(tag or '');
    if (tag == '') then
        return nil;
    end
    return string.format('!%s spells', tag);
end

--- Expansion category stubs (#44) — typed ! commands only.

function M.warehouse_summary()
    return '!warehouse';
end

function M.market_summary()
    return '!market';
end

function M.merc_board()
    return '!merc board';
end

function M.tracker_sync()
    return '!dwt sync';
end

function M.drift_board()
    return '!drift';
end

function M.fish_status()
    return '!fish';
end

function M.raid_board()
    return '!raid';
end

function M.arena_board()
    return '!arena';
end

function M.scan_target(treasure_hunter)
    if (treasure_hunter ~= nil) then
        return string.format('!scan 0 %d', treasure_hunter);
    end
    return '!scan';
end

function M.trustengage_status()
    return '!trustengage';
end

function M.trustengage_mode(mode)
    return string.format('!trustengage %d', mode or 0);
end

return M;
