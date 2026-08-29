--[[ screens/storage.lua — Trade: warehouse browse/take (#53) ]]

local cmds = require('cmds');
local data = require('data');
local H = require('screens._helpers');

local action_rows = H.action_rows;
local fire = H.fire;
local filter_match = H.filter_match;
local pick_character = H.pick_character;

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
            if (row.cmd ~= nil) then
                fire(ctx, row.cmd, 'Queued: ' .. row.cmd);
            end
        end,
    };
end

return M;
