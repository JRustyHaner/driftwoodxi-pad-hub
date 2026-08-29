--[[
* Stub screens for expansion categories (#44).
* Read rows queue typed ! commands; dim rows show planned child-issue work.
--]]

local cmds = require('cmds');
local H = require('screens._helpers');

local action_rows = H.action_rows;
local fire = H.fire;

local M = {};

local function stub_confirm(ctx, title, desc, cmd)
    return H.confirm_pick(title, desc, function(nav)
        fire(ctx, cmd, 'Queued: ' .. cmd);
        nav:pop();
    end);
end

local function on_stub_confirm(ctx, self, index, n)
    local row = self:rows()[index];
    if (row == nil) then
        return;
    end
    if (row.dim) then
        if (n.status ~= nil) then
            n.status = row.desc or 'Coming in a follow-up issue.';
        end
        return;
    end
    if (row.cmd ~= nil) then
        if (row.confirm) then
            n:push(stub_confirm(ctx, row.confirm_title or row.label, row.desc, row.cmd));
            return;
        end
        fire(ctx, row.cmd, row.ok or ('Queued: ' .. row.cmd));
    end
end

local function stub_screen(id, title, row_defs)
    return function(ctx)
        return {
            id = id,
            title = title,
            rows = action_rows(row_defs),
            on_confirm = function(self, index, n)
                on_stub_confirm(ctx, self, index, n);
            end,
        };
    end;
end

function M.storage(ctx)
    return stub_screen('storage', 'Storage', {
        { id = 'summary', label = 'Summary', desc = 'Account warehouse overview (!warehouse).', cmd = cmds.warehouse_summary() },
        { id = 'page', label = 'Browse shelf…', desc = 'Paged item list — #53.', dim = true },
        { id = 'put', label = 'Put / take…', desc = 'Move items — #53–#54.', dim = true },
    })(ctx);
end

function M.market(ctx)
    return stub_screen('market', 'Market', {
        { id = 'summary', label = 'Account line', desc = 'Listings, wallet, orders (!market).', cmd = cmds.market_summary() },
        { id = 'browse', label = 'Browse…', desc = 'Search listings — #56.', dim = true },
        { id = 'sell', label = 'Sell…', desc = 'List from bag — #56.', dim = true },
    })(ctx);
end

function M.merc(ctx)
    return stub_screen('merc', 'Merc', {
        { id = 'board', label = 'Board', desc = 'Who is for hire (!merc board).', cmd = cmds.merc_board() },
        { id = 'hire', label = 'Hire…', desc = 'Quote and hire — #55.', dim = true },
    })(ctx);
end

function M.quests(ctx)
    return stub_screen('quests', 'Quests', {
        { id = 'sync', label = 'Sync journal', desc = 'Refresh quest state (!dwt sync).', cmd = cmds.tracker_sync() },
        { id = 'list', label = 'Quest list…', desc = 'Pick active quest — #50.', dim = true },
    })(ctx);
end

function M.drift(ctx)
    return stub_screen('drift', 'Drift', {
        { id = 'board', label = 'Drift Board', desc = 'Daily and weekly contracts (!drift).', cmd = cmds.drift_board() },
        { id = 'accept', label = 'Accept…', desc = 'Contract picks — #51.', dim = true },
        { id = 'shop', label = 'Shops…', desc = 'Augments and outfitter — #52.', dim = true },
    })(ctx);
end

function M.fish(ctx)
    return stub_screen('fish', 'Fish', {
        { id = 'status', label = 'Skill & cap', desc = 'Rank cap and next catch (!fish).', cmd = cmds.fish_status() },
        { id = 'route', label = 'Full route…', desc = '0–110 plan — #47.', dim = true },
    })(ctx);
end

function M.raid(ctx)
    return stub_screen('raid', 'Raid', {
        { id = 'board', label = 'Trials', desc = 'Boss board and purse (!raid).', cmd = cmds.raid_board() },
        { id = 'enter', label = 'Enter trial…', desc = 'Warp in — #49 (confirm gate).', dim = true },
        { id = 'shop', label = 'Shop…', desc = 'Driftmarks gear — #58.', dim = true },
    })(ctx);
end

function M.arena(ctx)
    return stub_screen('arena', 'Arena', {
        { id = 'board', label = 'Gauntlet', desc = 'Arena status (!arena).', cmd = cmds.arena_board() },
        { id = 'enter', label = 'Enter…', desc = 'Warp party in — #48 (confirm gate).', dim = true },
    })(ctx);
end

function M.scan(ctx)
    return stub_screen('scan', 'Scan', {
        { id = 'scan', label = 'Scan target', desc = 'Target info and drops (!scan).', cmd = cmds.scan_target() },
        { id = 'scan_th', label = 'Scan (TH8)', desc = 'Drop rates at Treasure Hunter 8.', cmd = cmds.scan_target(8) },
    })(ctx);
end

function M.engage(ctx)
    return stub_screen('engage', 'Engage', {
        { id = 'trust', label = 'Trust engage', desc = 'Show or set !trustengage mode.', cmd = cmds.trustengage_status() },
        { id = 'mode0', label = 'Retail engage', desc = 'Master swings first.', cmd = cmds.trustengage_mode(0) },
        { id = 'mode1', label = 'Attack on engage', desc = 'Trusts commit when you engage.', cmd = cmds.trustengage_mode(1) },
        { id = 'dwengage', label = 'Auto-target…', desc = 'Spin to next party target — #45.', dim = true },
    })(ctx);
end

return M;
