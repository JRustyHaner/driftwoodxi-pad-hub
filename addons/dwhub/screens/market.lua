--[[ screens/market.lua — Trade: player market (#56, #57) ]]

local cmds = require('cmds');
local data = require('data');
local items = require('screens.items');
local H = require('screens._helpers');

local action_rows = H.action_rows;
local fire = H.fire;
local filter_match = H.filter_match;
local pick_list = H.pick_list;
local confirm_pick = H.confirm_pick;
local qty_pick = H.qty_pick;
local text_entry = H.text_entry;

local M = {};

local function trim(text)
    return (text or ''):gsub('^%s+', ''):gsub('%s+$', '');
end

local function paged_browser(ctx, opts)
    local buf = { '' };
    local get_entries = opts.get_entries;
    local get_info = opts.get_info;
    local request_page = opts.request_page;
    local header_fn = opts.header_fn;
    local id_prefix = opts.id_prefix or 'market';

    if (#get_entries() == 0) then
        request_page(1);
    end

    return {
        id = id_prefix .. ':browse',
        title = opts.title or 'Market',
        search = buf,
        rows = function()
            local info = get_info();
            local rows = {
                {
                    id = '__info',
                    label = header_fn(info),
                    dim = true,
                    desc = opts.info_desc or 'Market listings.',
                },
                {
                    id = '__refresh',
                    label = 'Refresh page',
                    desc = string.format('Reload page %d.', info.page or 1),
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
            local q = buf[1] or '';
            local matched = 0;
            for _, e in ipairs(get_entries()) do
                local label = string.format('%s  %s ×%d', e.ref or '?', e.name or '?', e.qty or 1);
                if (filter_match(label, q) or filter_match(e.name or '', q) or filter_match(e.ref or '', q)) then
                    rows[#rows + 1] = {
                        id = 'entry',
                        label = label,
                        desc = string.format('%s gil each · ref %s', e.price or 0, e.ref or '?'),
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
                    desc = 'Wait for !dwa reply, then Refresh.',
                };
            end
            return rows;
        end,
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil or row.id == '__info') then
                return;
            end
            if (row.id == '__refresh') then
                request_page(get_info().page or 1);
                ctx.set_status('Refreshing…');
                return;
            end
            if (row.id == '__prev') then
                request_page((get_info().page or 1) - 1);
                return;
            end
            if (row.id == '__next') then
                request_page((get_info().page or 1) + 1);
                return;
            end
            if (row.id == '__empty') then
                return;
            end
            if (opts.on_pick ~= nil and row.entry ~= nil) then
                opts.on_pick(row.entry, n);
            end
        end,
    };
end

local function listings_browser(ctx, on_pick)
    return paged_browser(ctx, {
        title = 'Listings',
        id_prefix = 'market:listings',
        info_desc = 'Auction house listings.',
        get_entries = function()
            return data.market_listings();
        end,
        get_info = function()
            return data.market_listings_info();
        end,
        request_page = function(page)
            data.request_market_page(ctx.enqueue, page);
        end,
        header_fn = function(info)
            return string.format('Listings %d/%d · %d total', info.page or 1, info.total_pages or 1, info.total or 0);
        end,
        on_pick = on_pick,
    });
end

local function orders_browser(ctx, on_pick)
    return paged_browser(ctx, {
        title = 'My orders',
        id_prefix = 'market:orders',
        info_desc = 'Your buy orders.',
        get_entries = function()
            return data.market_orders();
        end,
        get_info = function()
            return data.market_orders_info();
        end,
        request_page = function(page)
            data.request_market_orders(ctx.enqueue, page);
        end,
        header_fn = function(info)
            return string.format('Orders %d/%d · %d open', info.page or 1, info.total_pages or 1, info.total or 0);
        end,
        on_pick = on_pick,
    });
end

local function ref_entry(ctx, title, desc, on_ref)
    return text_entry(title, desc, '', function(text, nav)
        local ref = trim(text);
        if (ref == '') then
            return;
        end
        on_ref(ref, nav);
    end);
end

local function sell_from_bags_flow(ctx)
    return items.browse_bags_pick(ctx, function(entry, nav, owner)
        nav:push(qty_pick(function(qty, nav2)
            local stack = entry.name or ('item ' .. tostring(entry.itemid or '?'));
            local command = cmds.market_sell(stack);
            fire(ctx, command, 'Queued: ' .. command);
            nav2:pop();
            nav2:pop();
            nav2:pop();
        end));
    end);
end

local function post_order_flow(ctx)
    return items.browse_bags_pick(ctx, function(entry, nav)
        nav:push(qty_pick(function(qty, nav2)
            local stack = entry.name or ('item ' .. tostring(entry.itemid or '?'));
            local command = cmds.market_order(qty, stack);
            fire(ctx, command, 'Queued: ' .. command);
            nav2:pop();
            nav2:pop();
            nav2:pop();
        end));
    end);
end

local function buy_ref_flow(ctx)
    return pick_list('Buy listing', { 'Pick from browse…', 'Enter ref…' }, function(action, nav)
        if (action == 'Enter ref…') then
            nav:push(ref_entry(ctx, 'Listing ref', 'Tag like a1042 from !market page.', function(ref, nav2)
                local command = cmds.market_buy(ref);
                fire(ctx, command, 'Queued: ' .. command);
                nav2:pop();
                nav2:pop();
            end));
            return;
        end
        nav:push(listings_browser(ctx, function(entry, nav2)
            local command = cmds.market_buy(entry.ref);
            fire(ctx, command, 'Queued: ' .. command);
            nav2:pop();
            nav2:pop();
        end));
    end);
end

local function fill_order_flow(ctx)
    return pick_list('Fill order', { 'Pick from my orders…', 'Enter ref…' }, function(action, nav)
        if (action == 'Enter ref…') then
            nav:push(ref_entry(ctx, 'Order ref', 'Buy-order tag from !market orders.', function(ref, nav2)
                nav2:push(qty_pick(function(qty, nav3)
                    local command = cmds.market_fill(ref, qty);
                    fire(ctx, command, 'Queued: ' .. command);
                    nav3:pop();
                    nav3:pop();
                    nav3:pop();
                end));
            end));
            return;
        end
        nav:push(orders_browser(ctx, function(entry, nav2)
            nav2:push(qty_pick(function(qty, nav3)
                local command = cmds.market_fill(entry.ref, qty);
                fire(ctx, command, 'Queued: ' .. command);
                nav3:pop();
                nav3:pop();
                nav3:pop();
            end));
        end));
    end);
end

function M.market(ctx)
    return {
        id = 'market',
        title = 'Market',
        rows = action_rows({
            {
                id = 'summary',
                label = 'Account line',
                desc = 'Listings, wallet, orders, and box (!market).',
                cmd = cmds.market_summary(),
            },
            {
                id = 'browse',
                label = 'Browse listings…',
                desc = 'Paged auction house listings (!dwa page).',
            },
            {
                id = 'sell',
                label = 'Sell from bags…',
                desc = 'List an item from your bags (!market sell).',
            },
            {
                id = 'cancel',
                label = 'Cancel listing…',
                desc = 'Remove your sale listing by ref.',
            },
            {
                id = 'claim',
                label = 'Claim',
                desc = 'Claim sale proceeds (!market claim).',
                cmd = cmds.market_claim(),
            },
            {
                id = 'collect',
                label = 'Collect',
                desc = 'Collect from delivery box (!market collect).',
                cmd = cmds.market_collect(),
            },
            {
                id = 'buy',
                label = 'Buy by ref…',
                desc = 'Purchase a listing (!market buy).',
            },
            {
                id = 'order',
                label = 'Post order…',
                desc = 'Post a buy order from your bags.',
            },
            {
                id = 'orders',
                label = 'My orders…',
                desc = 'Browse your buy orders (!dwa orders).',
            },
            {
                id = 'fill',
                label = 'Fill order…',
                desc = 'Fill someone else\'s buy order (!market fill).',
            },
            {
                id = 'cancelorder',
                label = 'Cancel order…',
                desc = 'Cancel your buy order by ref.',
            },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then
                return;
            end
            if (row.id == 'browse') then
                n:push(listings_browser(ctx, nil));
                return;
            end
            if (row.id == 'sell') then
                n:push(sell_from_bags_flow(ctx));
                return;
            end
            if (row.id == 'cancel') then
                n:push(ref_entry(ctx, 'Listing ref', 'Your listing tag to cancel.', function(ref, nav)
                    local command = cmds.market_cancel(ref);
                    fire(ctx, command, 'Queued: ' .. command);
                    nav:pop();
                    nav:pop();
                end));
                return;
            end
            if (row.id == 'buy') then
                n:push(buy_ref_flow(ctx));
                return;
            end
            if (row.id == 'order') then
                n:push(post_order_flow(ctx));
                return;
            end
            if (row.id == 'orders') then
                n:push(orders_browser(ctx, nil));
                return;
            end
            if (row.id == 'fill') then
                n:push(fill_order_flow(ctx));
                return;
            end
            if (row.id == 'cancelorder') then
                n:push(ref_entry(ctx, 'Order ref', 'Buy-order tag to cancel.', function(ref, nav)
                    local command = cmds.market_cancelorder(ref);
                    fire(ctx, command, 'Queued: ' .. command);
                    nav:pop();
                    nav:pop();
                end));
                return;
            end
            if (row.cmd ~= nil) then
                fire(ctx, row.cmd, 'Queued: ' .. row.cmd);
            end
        end,
    };
end

return M;
