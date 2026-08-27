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
                rows[i] = { label = lab, desc = 'Select ' .. lab };
            end
            return rows;
        end,
        on_confirm = function(self, index, n)
            local rows = self:rows();
            local row = rows[index];
            if (row ~= nil) then
                on_pick(row.label, n);
            end
        end,
    };
end

--- Text entry screen: top-aligned buffer (OSK-safe). Confirm submits.
local function text_entry(title, desc, initial, on_submit)
    local buf = { initial or '' };
    return {
        id = 'text:' .. title,
        title = title,
        search = buf,
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
                rows[#rows + 1] = { id = '__refresh', label = 'Refresh list', desc = opts.refresh_desc or 'Ask the server again.' };
            end
            local labels = get_labels() or {};
            local matched = 0;
            for _, lab in ipairs(labels) do
                if (filter_match(lab, q)) then
                    rows[#rows + 1] = { id = 'item', label = lab, desc = 'Select ' .. lab, value = lab };
                    matched = matched + 1;
                end
            end
            if (matched == 0) then
                rows[#rows + 1] = { id = '__empty', label = '(' .. empty_hint .. ')', dim = true, desc = empty_hint };
            end
            if (opts.type_fallback) then
                rows[#rows + 1] = { id = '__type', label = 'Type name…', desc = 'Keyboard / OSK fallback.' };
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
            if (row.id == '__type') then
                n:push(text_entry(title, 'Type a name.', '', function(text, nav)
                    on_pick(text, nav);
                end));
                return;
            end
            on_pick(row.value or row.label, n);
        end,
    };
end

local function pick_character(ctx, title, char_opts, on_pick)
    char_opts = char_opts or { me = true };
    data.request_roster(ctx.enqueue);
    return live_pick(ctx, title, function()
        return data.char_labels(char_opts);
    end, on_pick, {
        refresh = function()
            data.request_roster(ctx.enqueue);
        end,
        refresh_desc = 'Queue !dws who for the account roster.',
        type_fallback = true,
        empty = 'No characters yet — Refresh',
    });
end

local function find_results_screen(ctx, title, on_pick_entry)
    local buf = { '' };
    return {
        id = 'find:' .. title,
        title = title,
        search = buf,
        rows = function()
            local q = buf[1] or '';
            local rows = {
                { id = '__search', label = 'Search', desc = 'Run find with the text above (!dwq find).' },
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
                rows[#rows + 1] = { id = '__empty', label = '(No results — Search above)', dim = true, desc = 'Type a query at the top, then Search.' };
            end
            rows[#rows + 1] = { id = '__type', label = 'Type item name…', desc = 'Fallback without find results.' };
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
                    ctx.set_status('Enter search text at the top.');
                    return;
                end
                data.request_roster(ctx.enqueue);
                data.request_find(ctx.enqueue, q);
                ctx.set_status('Finding: ' .. q);
                return;
            end
            if (row.id == '__empty') then
                return;
            end
            if (row.id == '__type') then
                n:push(text_entry('Item name', 'Typed item name.', '', function(text, nav)
                    on_pick_entry({ name = text, itemid = nil, typed = true }, nav);
                end));
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

    return {
        id = 'squad',
        title = 'Squad',
        rows = action_rows({
            { id = 'call', label = 'Call', desc = 'Summon registered squad members (!squad call).' },
            { id = 'dismiss', label = 'Dismiss', desc = 'Send the squad home (!squad dismiss).' },
            { id = 'list', label = 'List', desc = 'Print roster to chat (!squad list).' },
            { id = 'set', label = 'Set slot…', desc = 'Register a character to a squad slot.' },
            { id = 'clear', label = 'Clear slot…', desc = 'Un-register a slot.' },
            { id = 'engage', label = 'Engage', desc = 'All onto your current target.' },
            { id = 'disengage', label = 'Disengage', desc = 'All stand down and stay down.' },
            { id = 'come', label = 'Come', desc = 'Regroup on you.' },
            { id = 'rest', label = 'Rest', desc = 'Stand down and recover HP/MP.' },
            { id = 'behavior', label = 'Behavior…', desc = 'Aggressive / defensive / passive / off.' },
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
                data.request_roster(ctx.enqueue);
                fire(ctx, cmds.squad_list(), 'List + roster refresh.');
            elseif (id == 'set') then set_slot_menu(n);
            elseif (id == 'clear') then clear_slot_menu(n);
            elseif (id == 'engage') then fire(ctx, cmds.squad_engage(), 'Engage.');
            elseif (id == 'disengage') then fire(ctx, cmds.squad_disengage(), 'Disengage.');
            elseif (id == 'come') then fire(ctx, cmds.squad_come(), 'Come.');
            elseif (id == 'rest') then fire(ctx, cmds.squad_rest(), 'Rest.');
            elseif (id == 'behavior') then behavior_menu(n);
            end
        end,
    };
end

function M.jobs(ctx)
    local job_labels = {};
    for i, j in ipairs(cmds.JOBS) do
        job_labels[i] = j;
    end

    local function change_jobs(n)
        n:push(pick_character(ctx, 'Character', { me = true }, function(char, nav)
            local mains = {};
            for i, j in ipairs(job_labels) do
                mains[i] = j;
            end
            nav:push(pick_list('Main job', mains, function(main, nav2)
                local subs = { 'none' };
                for i, j in ipairs(job_labels) do
                    subs[#subs + 1] = j;
                end
                nav2:push(pick_list('Sub job', subs, function(sub, nav3)
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
            type_fallback = true,
            empty = 'No presets — Refresh or Type',
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
            type_fallback = true,
            empty = 'No sets — Refresh or Type',
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
                    { id = '__page2', label = 'List page 2', desc = 'Queue !port list ' .. tab .. ' 2' },
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
                    rows[#rows + 1] = { id = '__empty', label = '(No destinations yet)', dim = true, desc = 'Refresh after the list arrives in chat.' };
                end
                rows[#rows + 1] = { id = '__type', label = 'Type destination…', desc = 'Fallback go by name/number.' };
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
                if (row.id == '__empty') then return; end
                if (row.id == '__type') then
                    nav:push(text_entry('Destination', 'Name or list number.', '', function(dest, nav2)
                        fire(ctx, cmds.port_go(tab, dest), 'Go ' .. dest);
                        data.end_port_list();
                        nav2:pop();
                        nav2:pop();
                    end));
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
    local function after_item_for_transfer(mode, char, entry, n)
        if (entry.typed or entry.itemid == nil) then
            local cmd = (mode == 'send') and cmds.squad_send(char, entry.name, 1) or cmds.squad_fetch(char, entry.name, 1);
            fire(ctx, cmd, string.format('%s %s ↔ %s', mode, entry.name, char));
        else
            local cmd = (mode == 'send') and cmds.dwq_send(char, entry.itemid, entry.qty or 1)
                or cmds.dwq_fetch(char, entry.itemid, 1);
            fire(ctx, cmd, string.format('%s %s ↔ %s', mode, entry.name, char));
        end
        return_to_category(n);
    end

    local function transfer_flow(n, mode)
        local title = (mode == 'send') and 'Send to' or 'Fetch from';
        n:push(pick_character(ctx, title, { me = false }, function(char, nav)
            nav:push(find_results_screen(ctx, 'Item', function(entry, nav2)
                after_item_for_transfer(mode, char, entry, nav2);
            end));
        end));
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
                            { id = '__search', label = 'Search bags…', desc = 'Find an item then equip by id.' },
                            { id = '__type', label = 'Type name…', desc = 'Typed !squad equip fallback.' },
                        };
                    end,
                    on_confirm = function(self, index, nav3)
                        local row = self:rows()[index];
                        if (row == nil) then return; end
                        if (row.id == 'auto' or row.id == 'none') then
                            fire(ctx, cmds.dwq_equip(char, slot, row.id), string.format('Equip %s %s → %s', char, slot, row.id));
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
                        if (row.id == '__search') then
                            nav3:push(find_results_screen(ctx, 'Equip item', function(entry, nav4)
                                if (entry.itemid ~= nil) then
                                    fire(ctx, cmds.dwq_equip(char, slot, entry.itemid), string.format('Equip %s %s → %s', char, slot, entry.name));
                                else
                                    fire(ctx, cmds.squad_equip(char, slot, entry.name), string.format('Equip %s %s → %s', char, slot, entry.name));
                                end
                                return_to_category(nav4);
                            end));
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
            { id = 'who', label = 'Who', desc = 'Account bag fullness (!squad who).' },
            { id = 'find', label = 'Find…', desc = 'Search at top → pick from results.' },
            { id = 'send', label = 'Send…', desc = 'Target character → find → send.' },
            { id = 'fetch', label = 'Fetch…', desc = 'Source character → find → fetch.' },
            { id = 'box', label = 'In transit…', desc = '!squad box' },
            { id = 'gear', label = 'Gear…', desc = 'Show gear plan for a character.' },
            { id = 'equip', label = 'Equip…', desc = 'Character → slot → auto / find / none.' },
            { id = 'unpin', label = 'Unpin all…', desc = 'Clear pins on a character.' },
            { id = 'opt', label = 'Optimize me', desc = '!optimizegear on the logged-in character.' },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then return; end
            local id = row.id;
            if (id == 'who') then
                data.request_roster(ctx.enqueue);
                fire(ctx, cmds.squad_who(), 'Who → chat.');
            elseif (id == 'find') then
                n:push(find_results_screen(ctx, 'Find', function(entry, nav)
                    nav:push(pick_list('Action', { 'Send to…', 'Fetch from…', 'Done' }, function(action, nav2)
                        if (action == 'Done') then
                            return_to_category(nav2);
                            return;
                        end
                        local mode = (action == 'Send to…') and 'send' or 'fetch';
                        nav2:push(pick_character(ctx, mode == 'send' and 'Send to' or 'Fetch from', { me = false }, function(char, nav3)
                            after_item_for_transfer(mode, char, entry, nav3);
                        end));
                    end));
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
            elseif (id == 'opt') then fire(ctx, cmds.optimizegear(), 'Optimizegear.');
            end
        end,
    };
end

function M.home(nav, open_category)
    return {
        id = 'home',
        title = 'Pad Hub',
        rows = function()
            return {
                { label = 'Squad', desc = 'Call, dismiss, slots, field orders, behavior.' },
                { label = 'Jobs', desc = 'Change main/sub jobs or use lineup presets.' },
                { label = 'Items', desc = 'Find, send, fetch, and equip across your account.' },
                { label = 'Rules', desc = 'Assign gambit presets to squad members.' },
                { label = 'Port', desc = 'Home points, guides, outposts, teleport spells.' },
            };
        end,
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then
                return;
            end
            if (open_category ~= nil) then
                open_category(row.label, n);
            else
                n:push(M.placeholder(row.label, row.desc));
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
