--[[
* Hub screens: Home + category menus with live pick lists.
*
* ctx = { enqueue = function(cmd), set_status = function(msg) }
* Character / item / preset / port picks come from data.lua caches.
--]]

local cmds = require('cmds');
local data = require('data');

local M = {};

function M.placeholder(title, blurb)
    return {
        id = 'placeholder:' .. title,
        title = title,
        rows = function()
            return {
                { label = '(Coming in a follow-up PR)', dim = true, desc = blurb or 'Not implemented yet.' },
            };
        end,
        on_confirm = function() end,
    };
end

--- Fixed Home groups (MENU-IA). Home never grows beyond these five rows.
M.HOME_GROUPS = {
    {
        id = 'party',
        label = 'Party and Travel',
        desc = 'Squad, jobs, combat rules, and teleport.',
        categories = {
            { label = 'Squad', category = 'Squad', desc = 'Call, dismiss, slots, field orders, behavior.' },
            { label = 'Jobs', category = 'Jobs', desc = 'Change main/sub jobs or use lineup presets.' },
            { label = 'Rules', category = 'Rules', desc = 'Assign gambit presets to squad members.' },
            { label = 'Port', category = 'Port', desc = 'Home points, guides, outposts, teleport spells.' },
        },
    },
    {
        id = 'inventory',
        label = 'Inventory and Trade',
        desc = 'Account bags, gear, and economy.',
        categories = {
            { label = 'Items', category = 'Items', desc = 'Find, send, fetch, and equip across your account.' },
            { label = 'Storage', desc = 'Account warehouse (!warehouse) — coming soon.', dim = true },
            { label = 'Market', desc = 'Player market (!market) — coming soon.', dim = true },
            { label = 'Merc', desc = 'Mercenary board (!merc) — coming soon.', dim = true },
        },
    },
    {
        id = 'quests',
        label = 'Quests and Crafts',
        desc = 'Journal, contracts, and skilling.',
        categories = {
            { label = 'Quests', desc = 'Quest journal (/tracker) — coming soon.', dim = true },
            { label = 'Drift', desc = 'Drift Board contracts — coming soon.', dim = true },
            { label = 'Fish', desc = 'Fishing guide (!fish) — coming soon.', dim = true },
            { label = 'Craft', desc = 'Crafting ledger — coming soon.', dim = true },
        },
    },
    {
        id = 'instances',
        label = 'Instances',
        desc = 'Raids and Gauntlet from anywhere.',
        categories = {
            { label = 'Raid', desc = 'Boss trials (!raid) — coming soon.', dim = true },
            { label = 'Arena', desc = 'Gauntlet waves (!arena) — coming soon.', dim = true },
        },
    },
    {
        id = 'field',
        label = 'Field',
        desc = 'Target info and engage helpers.',
        categories = {
            { label = 'Scan', desc = 'Scan target (!scan) — coming soon.', dim = true },
            { label = 'Engage', desc = 'Auto-target and trust engage — coming soon.', dim = true },
        },
    },
};

function M.group(group_def, open_category)
    local title = group_def.label or 'Group';
    local entries = group_def.categories or {};
    return {
        id = 'group:' .. (group_def.id or title),
        title = title,
        rows = action_rows(entries),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil or row.dim) then
                if (row ~= nil and n.status ~= nil) then
                    n.status = row.desc or 'Coming soon.';
                end
                return;
            end
            local cat = entries[index] and entries[index].category;
            if (cat == nil) then
                return;
            end
            if (open_category ~= nil) then
                open_category(cat, n);
            end
        end,
    };
end

local function action_rows(entries)
    return function()
        local rows = {};
        for i, e in ipairs(entries) do
            rows[i] = { label = e.label, desc = e.desc, dim = e.dim, id = e.id };
        end
        return rows;
    end;
end

local function fire(ctx, command, ok_msg)
    if (ctx == nil or ctx.enqueue == nil) then
        return;
    end
    ctx.enqueue(command);
    if (ctx.set_status ~= nil) then
        ctx.set_status(ok_msg or ('Queued: ' .. command));
    end
end

local function filter_match(label, query)
    if (query == nil or query == '') then
        return true;
    end
    return string.find(string.lower(label or ''), string.lower(query), 1, true) ~= nil;
end

local function pick_list(title, labels, on_pick)
    return {
        id = 'pick:' .. title,
        title = title,
        rows = function()
            local rows = {};
            for i, lab in ipairs(labels) do
                if (type(lab) == 'table') then
                    rows[i] = lab;
                else
                    rows[i] = { label = lab, desc = 'Select ' .. lab, value = lab };
                end
            end
            return rows;
        end,
        on_confirm = function(self, index, n)
            local rows = self:rows();
            local row = rows[index];
            if (row ~= nil and not row.dim) then
                on_pick(row.value or row.label, n, row);
            end
        end,
    };
end

local function pick_rows(title, get_rows, on_pick)
    return {
        id = 'pickrows:' .. title,
        title = title,
        rows = get_rows,
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row ~= nil and not row.dim) then
                on_pick(row.value or row.label, n, row);
            end
        end,
    };
end

local function qty_pick(on_qty)
    return pick_list('Quantity', { '1', '5', '10', '99', 'Custom…' }, function(label, nav)
        if (label == 'Custom…') then
            nav:push(text_entry('Quantity', 'Stack size (1–99).', '1', function(text, nav2)
                local q = tonumber(text) or 1;
                if (q < 1) then
                    q = 1;
                elseif (q > 99) then
                    q = 99;
                end
                on_qty(q, nav2);
            end));
            return;
        end
        on_qty(tonumber(label) or 1, nav);
    end);
end

--- Text entry screen: top-aligned buffer (OSK-safe). Confirm submits.
local function text_entry(title, desc, initial, on_submit)
    local buf = { initial or '' };
    return {
        id = 'text:' .. title,
        title = title,
        search = buf,
        search_label = title,
        search_required = true,
        rows = function()
            return {
                { label = 'Submit', desc = desc or 'Confirm the text above.' },
                { label = 'Clear', desc = 'Clear the text field.' },
            };
        end,
        on_confirm = function(self, index, n)
            if (index == 2) then
                buf[1] = '';
                return;
            end
            local text = buf[1] or '';
            if (text == '') then
                return;
            end
            on_submit(text, n);
        end,
    };
end

local function live_pick(ctx, title, get_labels, on_pick, opts)
    opts = opts or {};
    local buf = { '' };
    local empty_hint = opts.empty or 'Waiting for server list…';

    return {
        id = 'live:' .. title,
        title = title,
        search = buf,
        rows = function()
            local q = buf[1] or '';
            local rows = {};
            if (opts.refresh ~= nil) then
                rows[#rows + 1] = {
                    id = '__refresh',
                    label = 'Refresh list',
                    desc = opts.refresh_desc or 'Ask the server again.',
                };
            end
            local labels = get_labels() or {};
            local matched = 0;
            for _, lab in ipairs(labels) do
                if (filter_match(lab, q)) then
                    rows[#rows + 1] = {
                        id = 'item',
                        label = lab,
                        desc = 'Select ' .. lab,
                        value = lab,
                    };
                    matched = matched + 1;
                end
            end
            if (matched == 0) then
                rows[#rows + 1] = {
                    id = '__empty',
                    label = '(' .. empty_hint .. ')',
                    dim = true,
                    desc = empty_hint,
                };
            end
            return rows;
        end,
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then
                return;
            end
            if (row.id == '__refresh') then
                if (opts.refresh ~= nil) then
                    opts.refresh();
                end
                if (ctx ~= nil and ctx.set_status ~= nil) then
                    ctx.set_status('Refreshing…');
                end
                return;
            end
            if (row.id == '__empty') then
                return;
            end
            on_pick(row.value or row.label, n);
        end,
    };
end

local function pick_character(ctx, title, char_opts, on_pick)
    char_opts = char_opts or { me = true };
    data.request_roster(ctx);
    return live_pick(ctx, title, function()
        return data.char_labels(char_opts);
    end, on_pick, {
        refresh = function()
            data.request_roster(ctx);
        end,
        refresh_desc = 'Queue !dws who for the account roster.',
        empty = 'No characters yet — Refresh',
    });
end

local CAST_CURRENT = '(current target)';

local function cast_target_pick(on_target)
    local labels = { CAST_CURRENT };
    for _, lab in ipairs(data.cast_target_labels(true)) do
        labels[#labels + 1] = lab;
    end
    return pick_list('Target', labels, function(label, nav)
        local target = (label == CAST_CURRENT) and nil or label;
        on_target(target, nav);
    end);
end

local function cast_spell_pick(ctx, tag, title, on_spell)
    data.request_spell_list(ctx, tag);
    return live_pick(ctx, title or ('Spell — ' .. tag), function()
        return data.spell_labels();
    end, on_spell, {
        refresh = function()
            data.request_spell_list(ctx, tag);
        end,
        refresh_desc = 'Queue !' .. tag .. ' spells',
        empty = 'No spells yet — Refresh',
    });
end

local function pop_to_category(nav)
    while (nav:depth() > 2) do
        if (not nav:pop()) then
            break;
        end
    end
end

local function cast_member_flow(ctx, n)
    data.request_roster(ctx);
    n:push(live_pick(ctx, 'Squad member', function()
        return data.squad_tag_labels();
    end, function(label, nav)
        local tag = data.squad_tag_by_label(label);
        nav:push(cast_spell_pick(ctx, tag, nil, function(spell, nav2)
            nav2:push(cast_target_pick(function(target, nav3)
                local cmd = cmds.job_cast(tag, spell, target);
                if (cmd ~= nil) then
                    fire(ctx, cmd, string.format('Cast %s → %s', tag, spell));
                end
                data.end_spell_list();
                pop_to_category(nav3);
            end));
        end));
    end, {
        refresh = function()
            data.request_roster(ctx);
            fire(ctx, cmds.squad_list(), 'Refreshing squad tags…');
        end,
        refresh_desc = 'Queue !dws who + !squad list.',
        empty = 'No squad slots — set slots, then Refresh',
    }));
end

local function cast_all_flow(ctx, n)
    n:push(pick_list('Job family', cmds.JOBS, function(job, nav)
        local tag = string.lower(job);
        nav:push(cast_spell_pick(ctx, tag, 'Spell — all' .. tag, function(spell, nav2)
            nav2:push(cast_target_pick(function(target, nav3)
                local cmd = cmds.job_cast_all(job, spell, target);
                if (cmd ~= nil) then
                    fire(ctx, cmd, string.format('Cast all %s → %s', job, spell));
                end
                data.end_spell_list();
                pop_to_category(nav3);
            end));
        end));
    end));
end

local find_results_screen -- forward decl (browse → find)

--- Items inside one bag container (viewport paging handled by nav).
local function bag_items_page_screen(ctx, owner_name, loc, loc_label, on_pick_entry)
    local buf = { '' };
    return {
        id = 'bagitems:' .. tostring(loc),
        title = loc_label,
        search = buf,
        rows = function()
            local q = buf[1] or '';
            local rows = {
                { id = '__refresh', label = 'Refresh bag', desc = 'Reload !dwq bag for ' .. owner_name },
            };
            local matched = 0;
            for _, e in ipairs(data.bag_items(loc)) do
                local label = string.format('%s ×%d', e.name or ('item ' .. e.itemid), e.qty or 1);
                if (filter_match(label, q) or filter_match(e.name or '', q)) then
                    rows[#rows + 1] = {
                        id = 'hit',
                        label = label,
                        desc = string.format('%s · itemid %d', owner_name, e.itemid),
                        entry = e,
                        owner = owner_name,
                    };
                    matched = matched + 1;
                end
            end
            if (matched == 0) then
                rows[#rows + 1] = {
                    id = '__empty',
                    label = '(Empty — Refresh or pick another bag)',
                    dim = true,
                    desc = 'No items in this container yet.',
                };
            end
            return rows;
        end,
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then return; end
            if (row.id == '__refresh') then
                data.request_bag(ctx.enqueue, owner_name);
                ctx.set_status('Loading bags for ' .. owner_name);
                return;
            end
            if (row.id == '__empty') then
                return;
            end
            on_pick_entry(row.entry, n, row.owner);
        end,
    };
end

--- Character's bags → container list → paged items.
local function browse_bags_screen(ctx, owner_name, on_pick_entry)
    data.request_roster(ctx);
    data.request_bag(ctx.enqueue, owner_name);
    local buf = { '' };
    return {
        id = 'bags:' .. owner_name,
        title = 'Bags — ' .. owner_name,
        search = buf,
        rows = function()
            local q = buf[1] or '';
            local rows = {
                { id = '__refresh', label = 'Refresh bags', desc = 'Queue !dwq bag ' .. owner_name },
                { id = '__find', label = 'Find instead…', desc = 'Account-wide search shortcut.' },
            };
            local locs = data.bag_locations();
            local matched = 0;
            for _, loc in ipairs(locs) do
                local label = string.format('%s  (%d/%d)', loc.label, loc.used, loc.size);
                if (loc.size == 0 and loc.count > 0) then
                    label = string.format('%s  (%d items)', loc.label, loc.count);
                end
                if (filter_match(label, q) or filter_match(loc.label, q)) then
                    rows[#rows + 1] = {
                        id = 'loc',
                        label = label,
                        desc = 'Open paged item list.',
                        loc = loc.loc,
                        loc_label = loc.label,
                    };
                    matched = matched + 1;
                end
            end
            if (matched == 0) then
                rows[#rows + 1] = { id = '__empty', label = '(No bags yet — Refresh)', dim = true, desc = 'Wait for !dwq bag reply, then Refresh.' };
            end
            return rows;
        end,
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then return; end
            if (row.id == '__refresh') then
                data.request_bag(ctx.enqueue, owner_name);
                ctx.set_status('Loading bags for ' .. owner_name);
                return;
            end
            if (row.id == '__find') then
                n:push(find_results_screen(ctx, 'Find', on_pick_entry));
                return;
            end
            if (row.id == '__empty') then return; end
            n:push(bag_items_page_screen(ctx, owner_name, row.loc, row.loc_label, on_pick_entry));
        end,
    };
end

find_results_screen = function(ctx, title, on_pick_entry)
    local buf = { '' };
    return {
        id = 'find:' .. title,
        title = title,
        search = buf,
        rows = function()
            local q = buf[1] or '';
            local rows = {
                { id = '__search', label = 'Search', desc = 'Run find with the filter text (!dwq find).' },
            };
            local matched = 0;
            for _, e in ipairs(data.find_entries()) do
                local owner = '?';
                for _, c in ipairs(data.state().chars) do
                    if (c.charid == e.charid) then
                        owner = c.name;
                        break;
                    end
                end
                local label = string.format('%s ×%d  (%s)', e.name or ('item ' .. e.itemid), e.qty or 1, owner);
                if (filter_match(label, q) or filter_match(e.name or '', q)) then
                    rows[#rows + 1] = {
                        id = 'hit',
                        label = label,
                        desc = string.format('itemid %d · charid %d', e.itemid, e.charid),
                        entry = e,
                        owner = owner,
                    };
                    matched = matched + 1;
                end
            end
            if (matched == 0) then
                rows[#rows + 1] = {
                    id = '__empty',
                    label = '(No results — filter + Search)',
                    dim = true,
                    desc = 'Highlight the filter field (Up), type, then Search.',
                };
            end
            return rows;
        end,
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then
                return;
            end
            if (row.id == '__search') then
                local q = (buf[1] or ''):gsub('^%s+', ''):gsub('%s+$', '');
                if (q == '') then
                    ctx.set_status('Highlight the filter field and enter text.');
                    return;
                end
                data.request_roster(ctx);
                data.request_find(ctx.enqueue, q);
                ctx.set_status('Finding: ' .. q);
                return;
            end
            if (row.id == '__empty') then
                return;
            end
            on_pick_entry(row.entry, n, row.owner);
        end,
    };
end

function M.squad(ctx)
    local function behavior_menu(n)
        n:push(pick_list('Behavior', cmds.BEHAVIORS, function(profile, nav)
            fire(ctx, cmds.squad_behavior(profile), 'Behavior → ' .. profile);
            nav:pop();
        end));
    end

    local function clear_slot_menu(n)
        n:push(pick_list('Clear slot', { '1', '2', '3', '4', '5' }, function(slot, nav)
            fire(ctx, cmds.squad_clear(tonumber(slot)), 'Clear slot ' .. slot);
            nav:pop();
        end));
    end

    local function set_slot_menu(n)
        n:push(pick_list('Set slot', { '1', '2', '3', '4', '5' }, function(slot, nav)
            nav:push(pick_character(ctx, 'Character for slot ' .. slot, { me = false }, function(name, nav2)
                fire(ctx, cmds.squad_set(tonumber(slot), name), string.format('Set %s → slot %s', name, slot));
                nav2:pop();
                nav2:pop();
            end));
        end));
    end

    local function squad_roster_screen()
        return {
            id = 'squad:roster',
            title = 'Squad roster',
            rows = function()
                local rows = {
                    { id = '__refresh', label = 'Refresh roster', desc = 'Queue !dws who + !squad list' },
                };
                for _, row in ipairs(data.squad_slot_rows()) do
                    rows[#rows + 1] = row;
                end
                return rows;
            end,
            on_confirm = function(self, index, n)
                local row = self:rows()[index];
                if (row == nil) then
                    return;
                end
                if (row.id == '__refresh') then
                    data.request_roster(ctx);
                    fire(ctx, cmds.squad_list(), 'Refreshing roster…');
                    return;
                end
            end,
        };
    end

    local function hints_flow(n, char)
        data.request_roster(ctx);
        fire(ctx, cmds.squad_hints(char), 'Hints → chat.');
        n:pop();
    end

    local function hints_menu(n)
        n:push(pick_character(ctx, 'Hints for', { me = true }, function(name, nav)
            hints_flow(nav, name);
        end));
    end

    return {
        id = 'squad',
        title = 'Squad',
        rows = action_rows({
            { id = 'call', label = 'Call', desc = 'Summon registered squad members (!squad call).' },
            { id = 'dismiss', label = 'Dismiss', desc = 'Send the squad home (!squad dismiss).' },
            { id = 'list', label = 'Roster', desc = 'Read-only squad slots 1–5.' },
            { id = 'set', label = 'Set slot…', desc = 'Register a character to a squad slot.' },
            { id = 'clear', label = 'Clear slot…', desc = 'Un-register a slot.' },
            { id = 'engage', label = 'Engage', desc = 'All onto your current target.' },
            { id = 'disengage', label = 'Disengage', desc = 'All stand down and stay down.' },
            { id = 'come', label = 'Come', desc = 'Regroup on you.' },
            { id = 'rest', label = 'Rest', desc = 'Stand down and recover HP/MP.' },
            { id = 'cast', label = 'Cast…', desc = 'Job tag → spell → target (!whm cure3 me).' },
            { id = 'castall', label = 'Cast all…', desc = 'Every member of a job (!allwhm curaga me).' },
            { id = 'behavior', label = 'Behavior…', desc = 'Aggressive / defensive / passive / off.' },
            { id = 'hints_me', label = 'Hints (me)', desc = 'Gear upgrades for logged-in character (!squad hints me).' },
            { id = 'hints', label = 'Hints…', desc = 'Pick member → what would make them stronger (!squad hints).' },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then
                return;
            end
            local id = row.id;
            if (id == 'call') then fire(ctx, cmds.squad_call(), 'Calling squad…');
            elseif (id == 'dismiss') then fire(ctx, cmds.squad_dismiss(), 'Dismissing…');
            elseif (id == 'list') then
                n:push(squad_roster_screen());
            elseif (id == 'set') then set_slot_menu(n);
            elseif (id == 'clear') then clear_slot_menu(n);
            elseif (id == 'engage') then fire(ctx, cmds.squad_engage(), 'Engage.');
            elseif (id == 'disengage') then fire(ctx, cmds.squad_disengage(), 'Disengage.');
            elseif (id == 'come') then fire(ctx, cmds.squad_come(), 'Come.');
            elseif (id == 'rest') then fire(ctx, cmds.squad_rest(), 'Rest.');
            elseif (id == 'cast') then cast_member_flow(ctx, n);
            elseif (id == 'castall') then cast_all_flow(ctx, n);
            elseif (id == 'behavior') then behavior_menu(n);
            elseif (id == 'hints_me') then fire(ctx, cmds.squad_hints('me'), 'Hints (me) → chat.');
            elseif (id == 'hints') then hints_menu(n);
            end
        end,
    };
end

function M.jobs(ctx)
    local function change_jobs(n)
        n:push(pick_character(ctx, 'Character', { me = true }, function(char, nav)
            data.request_jobs(ctx.enqueue);
            nav:push(pick_rows('Main job', function()
                return data.job_pick_rows(char, { include_none = false });
            end, function(main, nav2)
                nav2:push(pick_rows('Sub job', function()
                    return data.job_pick_rows(char, { include_none = true });
                end, function(sub, nav3)
                    fire(ctx, cmds.jobs_set(char, main, sub), string.format('Jobs %s → %s/%s', char, main, sub));
                    nav3:pop();
                    nav3:pop();
                    nav3:pop();
                end));
            end));
        end));
    end

    local function preset_pick(title, on_name)
        data.request_jobs(ctx.enqueue);
        data.request_job_presets(ctx.enqueue);
        return live_pick(ctx, title, function()
            return data.job_preset_labels();
        end, on_name, {
            refresh = function()
                data.request_job_presets(ctx.enqueue);
            end,
            refresh_desc = 'Queue !dwj list.',
            empty = 'No presets — Refresh',
        });
    end

    return {
        id = 'jobs',
        title = 'Jobs',
        rows = action_rows({
            { id = 'change', label = 'Change jobs…', desc = 'Pick character, then main and sub from the full job list.' },
            { id = 'use', label = 'Use preset…', desc = 'Apply a saved lineup (!jobs use).' },
            { id = 'save', label = 'Save preset…', desc = 'Save current lineup (!jobs save).' },
            { id = 'delete', label = 'Delete preset…', desc = 'Delete a saved lineup (!jobs delete).' },
            { id = 'list', label = 'List presets', desc = 'Refresh preset list from server.' },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then
                return;
            end
            local id = row.id;
            if (id == 'change') then
                change_jobs(n);
            elseif (id == 'use') then
                n:push(preset_pick('Use preset', function(name, nav)
                    fire(ctx, cmds.jobs_use(name), 'Use preset ' .. name);
                    nav:pop();
                end));
            elseif (id == 'save') then
                n:push(text_entry('Preset name', 'Name to save as.', '', function(name, nav)
                    fire(ctx, cmds.jobs_save(name), 'Save preset ' .. name);
                    nav:pop();
                end));
            elseif (id == 'delete') then
                n:push(preset_pick('Delete preset', function(name, nav)
                    fire(ctx, cmds.jobs_delete(name), 'Delete preset ' .. name);
                    nav:pop();
                end));
            elseif (id == 'list') then
                data.request_job_presets(ctx.enqueue);
                fire(ctx, cmds.jobs_list(), 'Presets refreshing…');
            end
        end,
    };
end

function M.rules(ctx)
    local function set_pick(on_name)
        data.request_rule_sets(ctx.enqueue);
        data.request_rule_presets(ctx.enqueue);
        return live_pick(ctx, 'Rule set', function()
            local labels = {};
            for _, n in ipairs(data.rule_preset_labels()) do
                labels[#labels + 1] = n;
            end
            for _, n in ipairs(data.rule_set_labels()) do
                labels[#labels + 1] = n;
            end
            return labels;
        end, on_name, {
            refresh = function()
                data.request_rule_sets(ctx.enqueue);
                data.request_rule_presets(ctx.enqueue);
            end,
            refresh_desc = 'Queue !dwg list + !dwg presets.',
            empty = 'No sets — Refresh',
        });
    end

    local function assign_flow(n, with_job)
        n:push(pick_character(ctx, 'Member', { me = true, all = true }, function(member, nav)
            nav:push(set_pick(function(setname, nav2)
                if (with_job) then
                    nav2:push(pick_list('When job', cmds.JOBS, function(job, nav3)
                        fire(ctx, cmds.rules_use_when(member, setname, job), string.format('Rules %s → %s when %s', member, setname, job));
                        nav3:pop(); nav3:pop(); nav3:pop();
                    end));
                else
                    fire(ctx, cmds.rules_use(member, setname), string.format('Rules %s → %s', member, setname));
                    nav2:pop(); nav2:pop();
                end
            end));
        end));
    end

    return {
        id = 'rules',
        title = 'Rules',
        rows = action_rows({
            { id = 'status', label = "What's running", desc = 'Print live rule sets (!squad rules).' },
            { id = 'assign', label = 'Assign set…', desc = 'Member or all → set from list → use.' },
            { id = 'when', label = 'Assign when job…', desc = 'Bind a set to a job on a member.' },
            { id = 'presets', label = 'Refresh shipped presets', desc = '!dwg presets into the pick lists.' },
            { id = 'behavior', label = 'Behavior…', desc = 'Same profiles as Squad behavior.' },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then return; end
            local id = row.id;
            if (id == 'status') then fire(ctx, cmds.rules_status(), 'Rules status → chat.');
            elseif (id == 'assign') then assign_flow(n, false);
            elseif (id == 'when') then assign_flow(n, true);
            elseif (id == 'presets') then
                data.request_rule_presets(ctx.enqueue);
                fire(ctx, cmds.rules_presets(), 'Presets refreshing…');
            elseif (id == 'behavior') then
                n:push(pick_list('Behavior', cmds.BEHAVIORS, function(profile, nav)
                    fire(ctx, cmds.squad_behavior(profile), 'Behavior → ' .. profile);
                    nav:pop();
                end));
            end
        end,
    };
end

function M.port(ctx)
    local function list_go(tab, title, n)
        data.request_port_list(ctx.enqueue, tab);
        local buf = { '' };
        n:push({
            id = 'port-tab:' .. tab,
            title = title,
            search = buf,
            rows = function()
                local q = buf[1] or '';
                local rows = {
                    { id = '__refresh', label = 'Refresh list', desc = 'Queue !port list ' .. tab },
                    { id = '__page2', label = 'Load server page 2', desc = 'Queue !port list ' .. tab .. ' 2' },
                };
                local matched = 0;
                for _, d in ipairs(data.port_entries()) do
                    if (filter_match(d.label, q) or filter_match(d.name or '', q)) then
                        rows[#rows + 1] = {
                            id = 'dest',
                            label = d.label,
                            desc = d.usable and 'Go (unlocked)' or 'Listed (may be locked)',
                            dim = not d.usable,
                            dest = d,
                        };
                        matched = matched + 1;
                    end
                end
                if (matched == 0) then
                    rows[#rows + 1] = {
                        id = '__empty',
                        label = '(No destinations yet — Refresh)',
                        dim = true,
                        desc = 'Refresh after the list arrives in chat.',
                    };
                end
                return rows;
            end,
            on_confirm = function(self, index, nav)
                local row = self:rows()[index];
                if (row == nil) then return; end
                if (row.id == '__refresh') then
                    data.request_port_list(ctx.enqueue, tab);
                    ctx.set_status('Listing ' .. tab .. '…');
                    return;
                end
                if (row.id == '__page2') then
                    data.request_port_list(ctx.enqueue, tab, 2);
                    ctx.set_status('Listing ' .. tab .. ' page 2…');
                    return;
                end
                if (row.id == '__empty') then
                    return;
                end
                if (row.dim) then
                    ctx.set_status('Destination locked — pick another.');
                    return;
                end
                local dest = row.dest;
                local key = dest.id or dest.name;
                fire(ctx, cmds.port_go(tab, key), 'Go ' .. (dest.name or key));
                data.end_port_list();
                nav:pop();
            end,
        });
    end

    return {
        id = 'port',
        title = 'Port',
        rows = action_rows({
            { id = 'home', label = 'Home nation', desc = 'Free nation home (!port home).' },
            { id = 'hp', label = 'Home points…', desc = 'List / go home points.' },
            { id = 'sg', label = 'Survival guides…', desc = 'List / go survival guides.' },
            { id = 'op', label = 'Outposts…', desc = 'List / go outposts.' },
            { id = 'sp', label = 'Teleport spells…', desc = 'List / go teleport spells.' },
            { id = 'search', label = 'Search…', desc = 'Type unambiguous zone/crystal name.' },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then return; end
            local id = row.id;
            if (id == 'home') then fire(ctx, cmds.port_home(), 'Port home.');
            elseif (id == 'hp') then list_go('hp', 'Home points', n);
            elseif (id == 'sg') then list_go('sg', 'Survival guides', n);
            elseif (id == 'op') then list_go('op', 'Outposts', n);
            elseif (id == 'sp') then list_go('sp', 'Teleport spells', n);
            elseif (id == 'search') then
                n:push(text_entry('Destination name', 'Unambiguous zone/crystal name.', '', function(name, nav)
                    fire(ctx, cmds.port_name(name), 'Port ' .. name);
                    nav:pop();
                end));
            end
        end,
    };
end

local function return_to_category(n)
    while (n:depth() > 2) do
        if (not n:pop()) then
            break;
        end
    end
end

function M.items(ctx)
    local function after_item_for_transfer(mode, char, entry, qty, n)
        local itemid = tonumber(entry.itemid) or 0;
        local label = entry.name or ('item ' .. tostring(itemid));
        if (itemid <= 0) then
            if (ctx.set_status ~= nil) then
                ctx.set_status('Missing item id — refresh bags and try again.');
            end
            return;
        end
        local cmd = (mode == 'send') and cmds.squad_send(char, itemid, qty) or cmds.squad_fetch(char, itemid, qty);
        fire(ctx, cmd, string.format('%s %s ×%d ↔ %s', mode, label, qty, char));
        return_to_category(n);
    end

    local function prompt_qty_then_transfer(mode, char, entry, n)
        n:push(qty_pick(function(qty, nav2)
            after_item_for_transfer(mode, char, entry, qty, nav2);
        end));
    end

    local function item_actions(entry, owner, nav)
        nav:push(pick_list('Action', { 'Send to…', 'Fetch from…', 'Done' }, function(action, nav2)
            if (action == 'Done') then
                return_to_category(nav2);
                return;
            end
            local mode = (action == 'Send to…') and 'send' or 'fetch';
            nav2:push(pick_character(ctx, mode == 'send' and 'Send to' or 'Fetch from', { me = false }, function(char, nav3)
                prompt_qty_then_transfer(mode, char, entry, nav3);
            end));
        end));
    end

    --- Browse someone's bags (paged). For Send: browse source then pick target, etc.
    local function browse_flow(n)
        n:push(pick_character(ctx, 'Whose bags', { me = true }, function(owner, nav)
            nav:push(browse_bags_screen(ctx, owner, function(entry, nav2, owner_name)
                item_actions(entry, owner_name or owner, nav2);
            end));
        end));
    end

    local function transfer_flow(n, mode)
        if (mode == 'send') then
            -- Browse source bags (usually me), pick item, then destination is chosen… 
            -- Simpler: pick destination first, then browse me/source bags for the item.
            n:push(pick_character(ctx, 'Send to', { me = false }, function(dest, nav)
                nav:push(pick_character(ctx, 'From whose bags', { me = true }, function(owner, nav2)
                    nav2:push(browse_bags_screen(ctx, owner, function(entry, nav3)
                        prompt_qty_then_transfer('send', dest, entry, nav3);
                    end));
                end));
            end));
        else
            n:push(pick_character(ctx, 'Fetch from', { me = false }, function(source, nav)
                nav:push(browse_bags_screen(ctx, source, function(entry, nav2)
                    prompt_qty_then_transfer('fetch', source, entry, nav2);
                end));
            end));
        end
    end

    local function equip_flow(n)
        n:push(pick_character(ctx, 'Character', { me = true }, function(char, nav)
            nav:push(pick_list('Slot', cmds.EQUIP_SLOTS, function(slot, nav2)
                nav2:push({
                    id = 'equip-item',
                    title = 'Item for ' .. slot,
                    search = { '' },
                    rows = function()
                        return {
                            { id = 'auto', label = 'auto', desc = 'Best available for this slot.' },
                            { id = 'none', label = 'none', desc = 'Empty / unpin this slot.' },
                            { id = '__browse', label = 'Browse bags…', desc = 'Paged bag list — no search required.' },
                            { id = '__search', label = 'Find…', desc = 'Account-wide find shortcut.' },
                            { id = '__type', label = 'Type name…', desc = 'Typed !squad equip fallback.' },
                        };
                    end,
                    on_confirm = function(self, index, nav3)
                        local row = self:rows()[index];
                        if (row == nil) then return; end
                        if (row.id == 'auto' or row.id == 'none') then
                            fire(ctx, cmds.squad_equip(char, slot, row.id), string.format('Equip %s %s → %s', char, slot, row.id));
                            return_to_category(nav3);
                            return;
                        end
                        if (row.id == '__type') then
                            nav3:push(text_entry('Item', 'Item name, auto, or none.', 'auto', function(item, nav4)
                                fire(ctx, cmds.squad_equip(char, slot, item), string.format('Equip %s %s → %s', char, slot, item));
                                return_to_category(nav4);
                            end));
                            return;
                        end
                        local function apply_equip(entry, nav4)
                            local item = entry.name or ('item ' .. tostring(entry.itemid or '?'));
                            fire(ctx, cmds.squad_equip(char, slot, item), string.format('Equip %s %s → %s', char, slot, item));
                            return_to_category(nav4);
                        end
                        if (row.id == '__browse') then
                            nav3:push(browse_bags_screen(ctx, char, apply_equip));
                            return;
                        end
                        if (row.id == '__search') then
                            nav3:push(find_results_screen(ctx, 'Equip item', apply_equip));
                        end
                    end,
                });
            end));
        end));
    end

    return {
        id = 'items',
        title = 'Items',
        rows = action_rows({
            { id = 'browse', label = 'Browse bags…', desc = 'Character → bag → paged item list (no search).' },
            { id = 'who', label = 'Who', desc = 'Account bag fullness (!squad who).' },
            { id = 'find', label = 'Find…', desc = 'Search at top → pick from results.' },
            { id = 'send', label = 'Send…', desc = 'Destination → browse bags → send.' },
            { id = 'fetch', label = 'Fetch…', desc = 'Source bags → pick item → fetch.' },
            { id = 'box', label = 'In transit…', desc = '!squad box' },
            { id = 'gear', label = 'Gear…', desc = 'Show gear plan for a character.' },
            { id = 'equip', label = 'Equip…', desc = 'Character → slot → auto / browse / find.' },
            { id = 'unpin', label = 'Unpin all…', desc = 'Clear pins on a character.' },
            { id = 'opt', label = 'Optimize…', desc = 'Dress logged-in character in best gear.' },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then return; end
            local id = row.id;
            if (id == 'browse') then
                browse_flow(n);
            elseif (id == 'who') then
                data.request_roster(ctx);
                fire(ctx, cmds.squad_who(), 'Who → chat.');
            elseif (id == 'find') then
                n:push(find_results_screen(ctx, 'Find', function(entry, nav, owner)
                    item_actions(entry, owner, nav);
                end));
            elseif (id == 'send') then transfer_flow(n, 'send');
            elseif (id == 'fetch') then transfer_flow(n, 'fetch');
            elseif (id == 'box') then fire(ctx, cmds.squad_box(), 'Box → chat.');
            elseif (id == 'gear') then
                n:push(pick_character(ctx, 'Character', { me = true }, function(char, nav)
                    fire(ctx, cmds.squad_gear(char), 'Gear ' .. char);
                    nav:pop();
                end));
            elseif (id == 'equip') then equip_flow(n);
            elseif (id == 'unpin') then
                n:push(pick_character(ctx, 'Character', { me = true }, function(char, nav)
                    fire(ctx, cmds.squad_unpin(char), 'Unpin ' .. char);
                    nav:pop();
                end));
            elseif (id == 'opt') then
                n:push(pick_list('Optimize', { 'Apply now', 'Preview only' }, function(action, nav)
                    if (action == 'Preview only') then
                        fire(ctx, cmds.optimizegear_preview(), 'Optimize preview → chat.');
                    else
                        fire(ctx, cmds.optimizegear(), 'Optimizegear.');
                    end
                    nav:pop();
                end));
            end
        end,
    };
end

function M.home(open_group)
    return {
        id = 'home',
        title = 'Pad Hub',
        rows = function()
            local rows = {};
            for i, g in ipairs(M.HOME_GROUPS) do
                rows[i] = {
                    id = g.id,
                    label = g.label,
                    desc = g.desc,
                };
            end
            return rows;
        end,
        on_confirm = function(self, index, n)
            local g = M.HOME_GROUPS[index];
            if (g == nil) then
                return;
            end
            if (open_group ~= nil) then
                open_group(g, n);
            end
        end,
        on_back = function()
            return 'close';
        end,
    };
end

M._fire = fire;
M._pick_list = pick_list;
M._text_entry = text_entry;
M._action_rows = action_rows;
M._live_pick = live_pick;
M._pick_character = pick_character;

return M;
