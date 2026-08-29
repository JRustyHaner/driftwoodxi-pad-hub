--[[ screens/storage.lua — Trade: warehouse browse/take (#53) + put/stash/pin (#54) ]]

local cmds = require('cmds');
local data = require('data');
local items = require('screens.items');
local H = require('screens._helpers');

local action_rows = H.action_rows;
local fire = H.fire;
local filter_match = H.filter_match;
local pick_list = H.pick_list;
local pick_character = H.pick_character;
local confirm_pick = H.confirm_pick;
local qty_pick = H.qty_pick;
local text_entry = H.text_entry;

local M = {};

local function shelf_header()
    local info = data.warehouse_info();
    local used = info.used or 0;
    local cap = info.capacity or 0;
    local page = info.page or 1;
    local pages = info.total_pages or 1;
    if (cap > 0) then
        return string.format('Shelf %d/%d · %d/%d slots', page, pages, used, cap);
    end
    return string.format('Shelf page %d/%d', page, pages);
end

local function shelf_item_rows(buf)
    local q = buf[1] or '';
    local rows = {};
    local matched = 0;
    for _, e in ipairs(data.warehouse_items()) do
        local label = string.format('#%d  %s ×%d', e.slot or 0, e.name or ('item ' .. e.itemid), e.qty or 1);
        if (filter_match(label, q) or filter_match(e.name or '', q)) then
            rows[#rows + 1] = {
                id = 'item',
                label = label,
                desc = string.format('Shelf slot %d · itemid %d', e.slot or 0, e.itemid),
                entry = e,
            };
            matched = matched + 1;
        end
    end
    if (matched == 0) then
        rows[#rows + 1] = {
            id = '__empty',
            label = '(Empty — Refresh or change page)',
            dim = true,
            desc = 'Wait for !dwu page reply, then Refresh.',
        };
    end
    return rows;
end

local function shelf_browser(ctx, on_pick_entry)
    data.request_roster(ctx);
    if (#data.warehouse_items() == 0) then
        data.request_warehouse_page(ctx.enqueue, 1);
    end
    local buf = { '' };

    return {
        id = 'warehouse:shelf',
        title = 'Warehouse shelf',
        search = buf,
        rows = function()
            local info = data.warehouse_info();
            local rows = {
                {
                    id = '__info',
                    label = shelf_header(),
                    dim = true,
                    desc = 'Account warehouse shelf page.',
                },
                {
                    id = '__refresh',
                    label = 'Refresh page',
                    desc = string.format('Reload !dwu page %d.', info.page or 1),
                },
            };
            if ((info.page or 1) > 1) then
                rows[#rows + 1] = {
                    id = '__prev',
                    label = 'Previous page',
                    desc = string.format('Load page %d.', (info.page or 1) - 1),
                };
            end
            if ((info.page or 1) < (info.total_pages or 1)) then
                rows[#rows + 1] = {
                    id = '__next',
                    label = 'Next page',
                    desc = string.format('Load page %d.', (info.page or 1) + 1),
                };
            end
            for _, row in ipairs(shelf_item_rows(buf)) do
                rows[#rows + 1] = row;
            end
            return rows;
        end,
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil or row.id == '__info') then
                return;
            end
            if (row.id == '__refresh') then
                local page = data.warehouse_info().page or 1;
                data.request_warehouse_page(ctx.enqueue, page);
                ctx.set_status('Loading warehouse page ' .. page);
                return;
            end
            if (row.id == '__prev') then
                local page = (data.warehouse_info().page or 1) - 1;
                data.request_warehouse_page(ctx.enqueue, page);
                ctx.set_status('Loading warehouse page ' .. page);
                return;
            end
            if (row.id == '__next') then
                local page = (data.warehouse_info().page or 1) + 1;
                data.request_warehouse_page(ctx.enqueue, page);
                ctx.set_status('Loading warehouse page ' .. page);
                return;
            end
            if (row.id == '__empty') then
                return;
            end
            if (on_pick_entry ~= nil and row.entry ~= nil) then
                on_pick_entry(row.entry, n);
            end
        end,
    };
end

local function take_character_pick(ctx, entry)
    return pick_character(ctx, 'Take to…', { me = true }, function(char, nav)
        local command = cmds.warehouse_take(entry.slot, char);
        fire(ctx, command, 'Queued: ' .. command);
        nav:pop();
        nav:pop();
    end);
end

local function take_item_browser(ctx)
    return shelf_browser(ctx, function(entry, nav)
        nav:push(take_character_pick(ctx, entry));
    end);
end

local function put_from_bags_flow(ctx)
    return items.browse_bags_pick(ctx, function(entry, nav, owner)
        nav:push(qty_pick(function(qty, nav2)
            local command = cmds.warehouse_put(owner, entry.loc, entry.slot, qty);
            fire(ctx, command, 'Queued: ' .. command);
            nav2:pop();
            nav2:pop();
            nav2:pop();
        end));
    end);
end

local function stash_all_confirm(ctx)
    return confirm_pick(
        'Stash all',
        'Move storable items from your bag into the warehouse? Rare, EX, and augmented gear stays put.',
        function(nav)
            fire(ctx, cmds.warehouse_stashall(), 'Queued: !warehouse stashall');
            nav:pop();
        end
    );
end

local function pull_list_entry(ctx)
    return text_entry(
        'Materials list',
        'Comma-separated item ids or names (!warehouse pull:…).',
        '',
        function(text, nav)
            if (text == nil or text == '') then
                return;
            end
            local command = cmds.warehouse_pull(text);
            fire(ctx, command, 'Queued: ' .. command);
            nav:pop();
        end
    );
end

local function pin_shelf_pick(ctx, pin)
    return shelf_browser(ctx, function(entry, nav)
        local command = pin and cmds.warehouse_pin(entry.slot) or cmds.warehouse_unpin(entry.slot);
        fire(ctx, command, 'Queued: ' .. command);
        nav:pop();
        nav:pop();
    end);
end

local function pin_menu(ctx)
    return pick_list('Pin / Unpin', { 'Pin shelf item…', 'Unpin shelf item…' }, function(action, nav)
        local pin = (action == 'Pin shelf item…');
        nav:push(pin_shelf_pick(ctx, pin));
    end);
end

local function buy_slot_confirm(ctx)
    fire(ctx, cmds.warehouse_buy(), 'Queued: !warehouse buy');
    return confirm_pick(
        'Buy warehouse slot',
        'Spend 100,000 gil for +1 account warehouse slot?',
        function(nav)
            fire(ctx, cmds.warehouse_buy_confirm(), 'Queued: !warehouse buy confirm');
            nav:pop();
        end
    );
end

function M.storage(ctx)
    return {
        id = 'storage',
        title = 'Storage',
        rows = action_rows({
            {
                id = 'summary',
                label = 'Summary',
                desc = 'Account warehouse overview and first shelf page (!warehouse).',
                cmd = cmds.warehouse_summary(),
            },
            {
                id = 'browse',
                label = 'Browse shelf…',
                desc = 'Paged item list from _DWUDATA.',
            },
            {
                id = 'take',
                label = 'Take…',
                desc = 'Pick shelf item, then character.',
            },
            {
                id = 'put',
                label = 'Put from bags…',
                desc = 'Browse bags, pick item and quantity.',
            },
            {
                id = 'stashall',
                label = 'Stash all…',
                desc = 'Empty storable bag items into the warehouse.',
            },
            {
                id = 'pull',
                label = 'Pull list…',
                desc = 'Withdraw a comma-separated materials list.',
            },
            {
                id = 'pin',
                label = 'Pin / Unpin…',
                desc = 'Keep shelf items out of Stash All.',
            },
            {
                id = 'buy',
                label = 'Buy slot…',
                desc = 'Price + confirm (+1 slot, 100,000 gil).',
            },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then
                return;
            end
            if (row.id == 'browse') then
                n:push(shelf_browser(ctx, nil));
                return;
            end
            if (row.id == 'take') then
                n:push(take_item_browser(ctx));
                return;
            end
            if (row.id == 'put') then
                n:push(put_from_bags_flow(ctx));
                return;
            end
            if (row.id == 'stashall') then
                n:push(stash_all_confirm(ctx));
                return;
            end
            if (row.id == 'pull') then
                n:push(pull_list_entry(ctx));
                return;
            end
            if (row.id == 'pin') then
                n:push(pin_menu(ctx));
                return;
            end
            if (row.id == 'buy') then
                n:push(buy_slot_confirm(ctx));
                return;
            end
            if (row.cmd ~= nil) then
                fire(ctx, row.cmd, 'Queued: ' .. row.cmd);
            end
        end,
    };
end

return M;
