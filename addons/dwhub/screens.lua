--[[
* Hub screens: Home + category menus.
*
* ctx = { enqueue = function(cmd), set_status = function(msg) }
--]]

local cmds = require('cmds');

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
            nav:push(text_entry('Character name', 'Name of your character for slot ' .. slot, '', function(name, nav2)
                fire(ctx, cmds.squad_set(tonumber(slot), name), string.format('Set %s → slot %s', name, slot));
                nav2:pop(); -- text
                nav2:pop(); -- slot pick
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
            elseif (id == 'list') then fire(ctx, cmds.squad_list(), 'List sent to chat.');
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
        n:push(text_entry('Character (me or name)', 'Who to change jobs for.', 'me', function(char, nav)
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

    return {
        id = 'jobs',
        title = 'Jobs',
        rows = action_rows({
            { id = 'change', label = 'Change jobs…', desc = 'Pick character, then main and sub from the full job list.' },
            { id = 'use', label = 'Use preset…', desc = 'Apply a saved lineup (!jobs use).' },
            { id = 'save', label = 'Save preset…', desc = 'Save current lineup (!jobs save).' },
            { id = 'delete', label = 'Delete preset…', desc = 'Delete a saved lineup (!jobs delete).' },
            { id = 'list', label = 'List presets', desc = 'Print presets to chat (!jobs list).' },
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
                n:push(text_entry('Preset name', 'Preset to use.', '', function(name, nav)
                    fire(ctx, cmds.jobs_use(name), 'Use preset ' .. name);
                    nav:pop();
                end));
            elseif (id == 'save') then
                n:push(text_entry('Preset name', 'Name to save as.', '', function(name, nav)
                    fire(ctx, cmds.jobs_save(name), 'Save preset ' .. name);
                    nav:pop();
                end));
            elseif (id == 'delete') then
                n:push(text_entry('Preset name', 'Preset to delete.', '', function(name, nav)
                    fire(ctx, cmds.jobs_delete(name), 'Delete preset ' .. name);
                    nav:pop();
                end));
            elseif (id == 'list') then
                fire(ctx, cmds.jobs_list(), 'Preset list sent to chat.');
            end
        end,
    };
end

function M.rules(ctx)
    local function assign_flow(n, with_job)
        n:push(text_entry('Member (or all)', 'Who receives the set.', 'all', function(member, nav)
            nav:push(text_entry('Set name', 'Shipped or account set name.', '', function(setname, nav2)
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
            { id = 'assign', label = 'Assign set…', desc = 'Member or all → set name → use.' },
            { id = 'when', label = 'Assign when job…', desc = 'Bind a set to a job on a member.' },
            { id = 'presets', label = 'List shipped presets', desc = '!squad rules presets' },
            { id = 'behavior', label = 'Behavior…', desc = 'Same profiles as Squad behavior.' },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then return; end
            local id = row.id;
            if (id == 'status') then fire(ctx, cmds.rules_status(), 'Rules status → chat.');
            elseif (id == 'assign') then assign_flow(n, false);
            elseif (id == 'when') then assign_flow(n, true);
            elseif (id == 'presets') then fire(ctx, cmds.rules_presets(), 'Presets → chat.');
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
        n:push({
            id = 'port-tab:' .. tab,
            title = title,
            search = { '' },
            rows = function()
                return {
                    { label = 'List page 1', desc = 'Queue !port list ' .. tab },
                    { label = 'List page 2', desc = 'Queue !port list ' .. tab .. ' 2' },
                    { label = 'Go (use text above)', desc = 'Queue !port go ' .. tab .. ' <text>' },
                };
            end,
            on_confirm = function(self, index, nav)
                if (index == 1) then
                    fire(ctx, cmds.port_list(tab), 'List ' .. tab);
                elseif (index == 2) then
                    fire(ctx, cmds.port_list(tab, 2), 'List ' .. tab .. ' p2');
                else
                    local dest = (self.search[1] or ''):gsub('^%s+', ''):gsub('%s+$', '');
                    if (dest == '') then
                        ctx.set_status('Enter a destination in the top field.');
                        return;
                    end
                    fire(ctx, cmds.port_go(tab, dest), 'Go ' .. dest);
                end
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
            { id = 'search', label = 'Search…', desc = 'Top field → !port <name> when unambiguous.' },
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

function M.items(ctx)
    local function equip_flow(n)
        n:push(text_entry('Character', 'Who to equip.', '', function(char, nav)
            nav:push(pick_list('Slot', cmds.EQUIP_SLOTS, function(slot, nav2)
                nav2:push(text_entry('Item (or auto / none)', 'Item name, auto, or none.', 'auto', function(item, nav3)
                    fire(ctx, cmds.squad_equip(char, slot, item), string.format('Equip %s %s → %s', char, slot, item));
                    nav3:pop(); nav3:pop(); nav3:pop();
                end));
            end));
        end));
    end

    return {
        id = 'items',
        title = 'Items',
        rows = action_rows({
            { id = 'who', label = 'Who', desc = 'Account bag fullness (!squad who).' },
            { id = 'find', label = 'Find…', desc = 'Search at top across all bags.' },
            { id = 'send', label = 'Send…', desc = 'Push item to another character.' },
            { id = 'fetch', label = 'Fetch…', desc = 'Pull item from another character.' },
            { id = 'box', label = 'In transit…', desc = '!squad box' },
            { id = 'gear', label = 'Gear…', desc = 'Show gear plan for a character.' },
            { id = 'equip', label = 'Equip…', desc = 'Pin slot item / auto / empty.' },
            { id = 'unpin', label = 'Unpin all…', desc = 'Clear pins on a character.' },
            { id = 'opt', label = 'Optimize me', desc = '!optimizegear on the logged-in character.' },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then return; end
            local id = row.id;
            if (id == 'who') then fire(ctx, cmds.squad_who(), 'Who → chat.');
            elseif (id == 'find') then
                n:push(text_entry('Find item', 'Search text for !squad find.', '', function(text, nav)
                    fire(ctx, cmds.squad_find(text), 'Find ' .. text);
                    nav:pop();
                end));
            elseif (id == 'send') then
                n:push(text_entry('Target character', 'Who receives the item.', '', function(char, nav)
                    nav:push(text_entry('Item name', 'Item to send.', '', function(item, nav2)
                        fire(ctx, cmds.squad_send(char, item, 1), string.format('Send %s → %s', item, char));
                        nav2:pop(); nav2:pop();
                    end));
                end));
            elseif (id == 'fetch') then
                n:push(text_entry('Source character', 'Who has the item.', '', function(char, nav)
                    nav:push(text_entry('Item name', 'Item to fetch.', '', function(item, nav2)
                        fire(ctx, cmds.squad_fetch(char, item, 1), string.format('Fetch %s ← %s', item, char));
                        nav2:pop(); nav2:pop();
                    end));
                end));
            elseif (id == 'box') then fire(ctx, cmds.squad_box(), 'Box → chat.');
            elseif (id == 'gear') then
                n:push(text_entry('Character', 'Gear report for whom.', '', function(char, nav)
                    fire(ctx, cmds.squad_gear(char), 'Gear ' .. char);
                    nav:pop();
                end));
            elseif (id == 'equip') then equip_flow(n);
            elseif (id == 'unpin') then
                n:push(text_entry('Character', 'Unpin all on whom.', '', function(char, nav)
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

-- Exported helpers for other category modules / later PRs
M._fire = fire;
M._pick_list = pick_list;
M._text_entry = text_entry;
M._action_rows = action_rows;

return M;
