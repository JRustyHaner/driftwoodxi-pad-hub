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

function M.warehouse_page(page)
    return string.format('!warehouse page %d', tonumber(page) or 1);
end

function M.warehouse_take(slot, char)
    return string.format('!warehouse take %d %s', tonumber(slot) or 0, char or '');
end

function M.warehouse_put(char, loc, slot, qty)
    return string.format('!warehouse put %s %d %d %d', char or '', tonumber(loc) or 0, tonumber(slot) or 0, tonumber(qty) or 1);
end

function M.warehouse_stashall()
    return '!warehouse stashall';
end

function M.warehouse_pull(list)
    local text = (list or ''):gsub('^%s+', ''):gsub('%s+$', '');
    return string.format('!warehouse pull:%s', text);
end

function M.warehouse_pin(slot)
    return string.format('!warehouse pin %d', tonumber(slot) or 0);
end

function M.warehouse_unpin(slot)
    return string.format('!warehouse unpin %d', tonumber(slot) or 0);
end

function M.warehouse_buy()
    return '!warehouse buy';
end

function M.warehouse_buy_confirm()
    return '!warehouse buy confirm';
end

function M.dwu_page(page)
    return string.format('!dwu page %d', tonumber(page) or 1);
end

function M.market_summary()
    return '!market';
end

function M.market_page(page)
    return string.format('!market page %d', tonumber(page) or 1);
end

function M.dwa_page(page)
    return string.format('!dwa page %d', tonumber(page) or 1);
end

function M.market_history()
    return '!market history';
end

function M.market_sell(stack)
    return string.format('!market sell %s', stack or '');
end

function M.market_buy(ref)
    return string.format('!market buy %s', ref or '');
end

function M.market_cancel(ref)
    if (ref ~= nil and ref ~= '') then
        return string.format('!market cancel %s', ref);
    end
    return '!market cancel';
end

function M.market_claim()
    return '!market claim';
end

function M.market_collect()
    return '!market collect';
end

function M.market_order(qty, stack)
    return string.format('!market order %d %s', tonumber(qty) or 1, stack or '');
end

function M.market_orders(page)
    if (page ~= nil) then
        return string.format('!market orders %d', tonumber(page) or 1);
    end
    return '!market orders';
end

function M.dwa_orders(page)
    return string.format('!dwa orders %d', tonumber(page) or 1);
end

function M.market_fill(ref, count)
    if (count ~= nil) then
        return string.format('!market fill %d %s', tonumber(count) or 1, ref or '');
    end
    return string.format('!market fill %s', ref or '');
end

function M.market_cancelorder(ref)
    return string.format('!market cancelorder %s', ref or '');
end

function M.merc_board(job, page)
    local parts = { '!merc', 'board' };
    if (job ~= nil and job ~= '' and job ~= 'ALL') then
        parts[#parts + 1] = string.upper(job);
    end
    if (page ~= nil) then
        parts[#parts + 1] = tostring(tonumber(page) or 1);
    end
    return table.concat(parts, ' ');
end

function M.dwm_board(job, page)
    local parts = { '!dwm', 'board' };
    if (job ~= nil and job ~= '' and job ~= 'ALL') then
        parts[#parts + 1] = string.upper(job);
    end
    if (page ~= nil) then
        parts[#parts + 1] = tostring(tonumber(page) or 1);
    end
    return table.concat(parts, ' ');
end

function M.merc_info(ref)
    return string.format('!merc info %s', ref or '');
end

function M.merc_quote(ref)
    return string.format('!merc quote %s', ref or '');
end

function M.merc_hire(ref)
    return string.format('!merc hire %s', ref or '');
end

function M.merc_call(loadout)
    if (loadout ~= nil and loadout ~= '') then
        return string.format('!merc call %s', loadout);
    end
    return '!merc call';
end

function M.merc_dismiss()
    return '!merc dismiss';
end

function M.merc_contracts()
    return '!merc contracts';
end

function M.merc_list()
    return '!merc list';
end

function M.merc_unlist()
    return '!merc unlist';
end

function M.merc_listings()
    return '!merc listings';
end

function M.merc_earnings()
    return '!merc earnings';
end

function M.merc_claim()
    return '!merc claim';
end

function M.tracker_sync()
    return '!dwt sync';
end

function M.drift_board()
    return '!drift';
end

M.DRIFT_SLOTS = { 'd1', 'd2', 'd3', 'd4', 'w1', 'w2', 'w3', 'w4' };

function M.drift_balance()
    return '!drift balance';
end

function M.drift_accept(slot)
    return string.format('!drift accept %s', slot);
end

function M.drift_abandon(slot)
    return string.format('!drift abandon %s', slot);
end

M.DRIFT_AUGMENT_SLOTS = { 'x1', 'x2', 'x3', 'x4' };

function M.drift_augments()
    return '!drift augments';
end

function M.drift_augment_price(slot)
    return string.format('!drift augment %s', slot);
end

function M.drift_confirm()
    return '!drift confirm';
end

function M.drift_shelf(job)
    return string.format('!drift shelf %s', string.lower(job or ''));
end

function M.drift_buy(item_id)
    return string.format('!drift buy %d', item_id or 0);
end

function M.fish_status()
    return '!fish';
end

function M.fish_next()
    return '!fish next';
end

function M.fish_rank()
    return '!fish rank';
end

function M.fish_route()
    return '!fish route';
end

function M.raid_board()
    return '!raid';
end

M.RAID_BOSSES = {
    'tidebound', 'riptide', 'wakeshell', 'maelstrom',
    'gravegaze', 'cragmaw', 'zephyr', 'howlmane',
};

M.RAID_TIERS = {
    'easy', 'normal', 'difficult', 'savage',
};

function M.raid_enter(boss, tier)
    return string.format('!raid enter %s %s', boss, tier);
end

function M.raid_leave()
    return '!raid leave';
end

function M.raid_marks()
    return '!raid marks';
end

M.RAID_SHOP_TABS = { 'supplies', 'onehand', 'twohand', 'ranged', 'armor' };

function M.raid_shop(tab)
    return string.format('!raid shop %s', tab or 'supplies');
end

function M.raid_buy(item)
    return string.format('!raid buy %s', item or '');
end

function M.raid_confirm()
    return '!raid confirm';
end

function M.raid_reforge()
    return '!raid reforge';
end

function M.arena_board()
    return '!arena';
end

function M.arena_enter()
    return '!arena enter';
end

function M.arena_leave()
    return '!arena leave';
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

function M.dwengage_on()
    return '/dwengage on';
end

function M.dwengage_off()
    return '/dwengage off';
end

return M;
