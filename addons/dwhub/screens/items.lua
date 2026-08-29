--[[ screens/items.lua ]]

local cmds = require('cmds');
local data = require('data');
local H = require('screens._helpers');

local action_rows = H.action_rows;
local fire = H.fire;
local filter_match = H.filter_match;
local pick_list = H.pick_list;
local qty_pick = H.qty_pick;
local text_entry = H.text_entry;
local live_pick = H.live_pick;
local pick_character = H.pick_character;
local confirm_pick = H.confirm_pick;
local pop_to_category = H.pop_to_category;

local M = {};

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

local function return_to_category(n)
    pop_to_category(n);
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
            { id = 'box', label = 'In transit…', desc = 'Pick character → !dwq box (delivery shelf).' },
            { id = 'gear', label = 'Gear…', desc = 'Show gear plan for a character.' },
            { id = 'equip', label = 'Equip…', desc = 'Character → slot → auto / browse / find.' },
            { id = 'unpin', label = 'Unpin all…', desc = 'Clear gear pins (!squad equip <slot> auto, every slot).' },
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
            elseif (id == 'box') then
                n:push(pick_character(ctx, 'In transit for', { me = true }, function(char, nav)
                    fire(ctx, cmds.dwq_box(char), 'In transit for ' .. char .. ' → chat.');
                    nav:pop();
                end));
            elseif (id == 'gear') then
                n:push(pick_character(ctx, 'Character', { me = true }, function(char, nav)
                    fire(ctx, cmds.squad_gear(char), 'Gear ' .. char);
                    nav:pop();
                end));
            elseif (id == 'equip') then equip_flow(n);
            elseif (id == 'unpin') then
                n:push(pick_character(ctx, 'Character', { me = true }, function(char, nav)
                    for _, slot in ipairs(cmds.EQUIP_SLOTS) do
                        fire(ctx, cmds.squad_equip(char, slot, 'auto'), string.format('Unpin %s (%s)', char, slot));
                    end
                    nav:pop();
                end));
            elseif (id == 'opt') then
                n:push(pick_list('Optimize', { 'Apply now', 'Preview only' }, function(action, nav)
                    if (action == 'Preview only') then
                        fire(ctx, cmds.optimizegear_preview(), 'Optimize preview → chat.');
                        nav:pop();
                        return;
                    end
                    nav:push(confirm_pick(
                        'Optimize gear',
                        'Dress your character in the best gear owned for this job. The server refuses while engaged.',
                        function(nav2)
                            fire(ctx, cmds.optimizegear(), 'Optimizegear.');
                            nav2:pop();
                            nav2:pop();
                        end
                    ));
                end));
            end
        end,
    };
end

--- Pick a character, browse bags, and invoke on_pick(entry, nav, owner_name).
function M.browse_bags_pick(ctx, on_pick)
    return pick_character(ctx, 'Whose bags', { me = true }, function(owner, nav)
        nav:push(browse_bags_screen(ctx, owner, function(entry, nav2, owner_name)
            on_pick(entry, nav2, owner_name or owner);
        end));
    end);
end

return M;
