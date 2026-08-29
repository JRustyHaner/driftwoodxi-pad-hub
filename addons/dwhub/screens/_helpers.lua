--[[ screens/_helpers.lua — shared pick lists and command fire ]]

local cmds = require('cmds');
local data = require('data');

local M = {};

local function action_rows(entries)
    return function()
        local rows = {};
        for i, e in ipairs(entries) do
            rows[i] = { label = e.label, desc = e.desc, dim = e.dim, id = e.id };
        end
        return rows;
    end;
end

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
M.action_rows = action_rows;
M.fire = fire;
M.filter_match = filter_match;
M.pick_list = pick_list;
M.pick_rows = pick_rows;
M.qty_pick = qty_pick;
M.text_entry = text_entry;
M.live_pick = live_pick;
M.pick_character = pick_character;
M.cast_target_pick = cast_target_pick;
M.cast_spell_pick = cast_spell_pick;
M.pop_to_category = pop_to_category;
M.cast_member_flow = cast_member_flow;
M.cast_all_flow = cast_all_flow;

return M;
