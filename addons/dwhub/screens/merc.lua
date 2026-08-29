--[[ screens/merc.lua — Trade: mercenary board (#55) ]]

local cmds = require('cmds');
local data = require('data');
local H = require('screens._helpers');

local action_rows = H.action_rows;
local fire = H.fire;
local filter_match = H.filter_match;
local pick_list = H.pick_list;
local confirm_pick = H.confirm_pick;
local text_entry = H.text_entry;

local M = {};

local function board_header()
    local info = data.merc_board_info();
    local page = info.page or 1;
    local pages = info.total_pages or 1;
    local total = info.total or 0;
    local job = info.job_filter;
    if (job ~= nil and job ~= '' and job ~= 'ALL') then
        return string.format('%s board %d/%d · %d listed', job, page, pages, total);
    end
    return string.format('Board %d/%d · %d listed', page, pages, total);
end

local function board_entry_rows(buf)
    local q = buf[1] or '';
    local rows = {};
    local matched = 0;
    for _, e in ipairs(data.merc_board_entries()) do
        local label = string.format('%s  %s %d  (%s)', e.ref or '?', e.job or '?', e.level or 0, e.name or '?');
        if (filter_match(label, q) or filter_match(e.name or '', q) or filter_match(e.job or '', q)) then
            rows[#rows + 1] = {
                id = 'entry',
                label = label,
                desc = string.format('%s gil · ref %s', e.price or 0, e.ref or '?'),
                entry = e,
            };
            matched = matched + 1;
        end
    end
    if (matched == 0) then
        rows[#rows + 1] = {
            id = '__empty',
            label = '(Empty — Refresh or change filter)',
            dim = true,
            desc = 'Wait for !dwm board reply, then Refresh.',
        };
    end
    return rows;
end

local function board_browser(ctx, job_filter, on_pick_entry)
    if (#data.merc_board_entries() == 0) then
        data.request_merc_board(ctx.enqueue, job_filter, 1);
    end
    local buf = { '' };
    local filter = job_filter;

    return {
        id = 'merc:board:' .. tostring(filter or 'all'),
        title = 'Merc board',
        search = buf,
        rows = function()
            local info = data.merc_board_info();
            local rows = {
                {
                    id = '__info',
                    label = board_header(),
                    dim = true,
                    desc = 'Mercenaries for hire.',
                },
                {
                    id = '__refresh',
                    label = 'Refresh board',
                    desc = string.format('Reload !dwm board%s.', filter and (' ' .. filter) or ''),
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
            for _, row in ipairs(board_entry_rows(buf)) do
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
                local page = data.merc_board_info().page or 1;
                data.request_merc_board(ctx.enqueue, filter, page);
                ctx.set_status('Loading merc board…');
                return;
            end
            if (row.id == '__prev') then
                local page = (data.merc_board_info().page or 1) - 1;
                data.request_merc_board(ctx.enqueue, filter, page);
                ctx.set_status('Loading merc board page ' .. page);
                return;
            end
            if (row.id == '__next') then
                local page = (data.merc_board_info().page or 1) + 1;
                data.request_merc_board(ctx.enqueue, filter, page);
                ctx.set_status('Loading merc board page ' .. page);
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

local function job_filter_pick(ctx, on_job)
    local jobs = {
        { label = 'All jobs', desc = 'Every listing on the board.', value = 'ALL' },
    };
    for _, job in ipairs(cmds.JOBS) do
        jobs[#jobs + 1] = {
            label = job,
            desc = string.format('Filter board to %s listings.', job),
            value = job,
        };
    end
    return pick_list('Job filter', jobs, function(job, nav)
        on_job(job, nav);
    end);
end

local function board_flow(ctx, on_pick_entry)
    return job_filter_pick(ctx, function(job, nav)
        nav:push(board_browser(ctx, job == 'ALL' and nil or job, on_pick_entry));
    end);
end

local function hire_confirm_chain(ctx, entry, nav)
    local ref = entry.ref or '';
    local label = entry.name or ref;
    fire(ctx, cmds.merc_quote(ref), 'Queued: ' .. cmds.merc_quote(ref));
    nav:push(confirm_pick(
        'Hire mercenary',
        string.format('Quote %s (%s) and proceed to hire?', label, ref),
        function(nav2)
            nav2:push(confirm_pick(
                'Confirm hire',
                string.format('Spend gil to hire %s? The server may ask again in chat.', label),
                function(nav3)
                    fire(ctx, cmds.merc_hire(ref), 'Queued: ' .. cmds.merc_hire(ref));
                    nav3:pop();
                    nav3:pop();
                    nav3:pop();
                    nav3:pop();
                end
            ));
        end
    ));
end

local function hire_by_ref_entry(ctx)
    return text_entry(
        'Merc ref',
        'Board ref from !merc board (e.g. m101).',
        '',
        function(text, nav)
            local ref = (text or ''):gsub('^%s+', ''):gsub('%s+$', '');
            if (ref == '') then
                return;
            end
            hire_confirm_chain(ctx, { ref = ref, name = ref }, nav);
        end
    );
end

local function hire_flow(ctx)
    return pick_list('Hire', { 'Pick from board…', 'Enter ref…' }, function(action, nav)
        if (action == 'Enter ref…') then
            nav:push(hire_by_ref_entry(ctx));
            return;
        end
        nav:push(board_flow(ctx, function(entry, nav2)
            hire_confirm_chain(ctx, entry, nav2);
        end));
    end);
end

local function call_flow(ctx)
    return pick_list('Call merc', { 'Default loadout', 'Named loadout…' }, function(action, nav)
        if (action == 'Default loadout') then
            fire(ctx, cmds.merc_call(), 'Queued: !merc call');
            nav:pop();
            return;
        end
        nav:push(text_entry(
            'Loadout name',
            'Optional loadout for !merc call.',
            '',
            function(text, nav2)
                local loadout = (text or ''):gsub('^%s+', ''):gsub('%s+$', '');
                if (loadout == '') then
                    return;
                end
                fire(ctx, cmds.merc_call(loadout), 'Queued: ' .. cmds.merc_call(loadout));
                nav2:pop();
                nav2:pop();
            end
        ));
    end);
end

local function unlist_confirm(ctx)
    return confirm_pick(
        'Unlist mercenary',
        'Remove your character from the merc board?',
        function(nav)
            fire(ctx, cmds.merc_unlist(), 'Queued: !merc unlist');
            nav:pop();
        end
    );
end

function M.merc(ctx)
    return {
        id = 'merc',
        title = 'Merc',
        rows = action_rows({
            {
                id = 'board',
                label = 'Board…',
                desc = 'Job filter and paged listings (!merc board / !dwm).',
            },
            {
                id = 'hire',
                label = 'Hire…',
                desc = 'Quote, confirm twice, then !merc hire.',
            },
            {
                id = 'call',
                label = 'Call…',
                desc = 'Summon hired merc (!merc call [loadout]).',
            },
            {
                id = 'dismiss',
                label = 'Dismiss',
                desc = 'Send active merc away (!merc dismiss).',
                cmd = cmds.merc_dismiss(),
            },
            {
                id = 'list',
                label = 'List yours',
                desc = 'Put a character up for hire (!merc list).',
                cmd = cmds.merc_list(),
            },
            {
                id = 'unlist',
                label = 'Unlist…',
                desc = 'Take your listing down (!merc unlist).',
            },
            {
                id = 'earnings',
                label = 'Earnings',
                desc = 'Merc income summary (!merc earnings).',
                cmd = cmds.merc_earnings(),
            },
            {
                id = 'claim',
                label = 'Claim',
                desc = 'Collect merc earnings (!merc claim).',
                cmd = cmds.merc_claim(),
            },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then
                return;
            end
            if (row.id == 'board') then
                n:push(board_flow(ctx, function(entry, nav)
                    fire(ctx, cmds.merc_info(entry.ref), 'Queued: ' .. cmds.merc_info(entry.ref));
                    nav:pop();
                    nav:pop();
                end));
                return;
            end
            if (row.id == 'hire') then
                n:push(hire_flow(ctx));
                return;
            end
            if (row.id == 'call') then
                n:push(call_flow(ctx));
                return;
            end
            if (row.id == 'unlist') then
                n:push(unlist_confirm(ctx));
                return;
            end
            if (row.cmd ~= nil) then
                fire(ctx, row.cmd, 'Queued: ' .. row.cmd);
            end
        end,
    };
end

return M;
