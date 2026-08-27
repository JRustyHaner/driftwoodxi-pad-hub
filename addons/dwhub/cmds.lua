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

function M.rules_use(member, setname)
    return string.format('!squad rules use %s %s', member, setname);
end

function M.rules_use_when(member, setname, job)
    return string.format('!squad rules use %s %s when %s', member, setname, job);
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

function M.squad_send(char, item, qty)
    qty = qty or 1;
    return string.format('!squad send %s %s %d', char, item, qty);
end

function M.squad_fetch(char, item, qty)
    qty = qty or 1;
    return string.format('!squad fetch %s %s %d', char, item, qty);
end

function M.squad_box()
    return '!squad box';
end

function M.squad_gear(char)
    return string.format('!squad gear %s', char);
end

function M.squad_equip(char, slot, item)
    return string.format('!squad equip %s %s %s', char, slot, item);
end

function M.squad_unpin(char)
    return string.format('!squad unpin %s', char);
end

function M.optimizegear()
    return '!optimizegear';
end

-- Machine-channel reads / id-based bag writes (same dispatch as dw* windows).
function M.dws_who()
    return '!dws who';
end

function M.dwj_who()
    return '!dwj who';
end

function M.dwj_list()
    return '!dwj list';
end

function M.dwq_find(text)
    return string.format('!dwq find %s', text);
end

function M.dwq_bag(char)
    return string.format('!dwq bag %s', char);
end

function M.dwq_send(char, itemid, qty)
    qty = qty or 1;
    return string.format('!dwq send %s %d %d', char, itemid, qty);
end

function M.dwq_fetch(char, itemid, qty)
    qty = qty or 1;
    return string.format('!dwq fetch %s %d %d', char, itemid, qty);
end

function M.dwq_equip(char, slot, itemid_or_token)
    return string.format('!dwq equip %s %s %s', char, slot, tostring(itemid_or_token));
end

function M.dwg_list()
    return '!dwg list';
end

function M.dwg_presets()
    return '!dwg presets';
end

return M;
