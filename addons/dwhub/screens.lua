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
