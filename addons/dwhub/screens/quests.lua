--[[ screens/quests.lua — Progress: quest journal from _DWTDATA (#50) ]]

local cmds = require('cmds');
local data = require('data');
local H = require('screens._helpers');

local action_rows = H.action_rows;
local fire = H.fire;
local filter_match = H.filter_match;

local M = {};

local function read_only_list(title, get_entries, label_fn)
    return function(ctx)
        local buf = { '' };
        return {
            id = 'tracker:' .. title,
            title = title,
            search = buf,
            rows = function()
                local q = buf[1] or '';
                local rows = {
                    {
                        id = '__refresh',
                        label = 'Refresh journal',
                        desc = 'Queue !dwt sync and wait for _DWTDATA.',
                    },
                };
                local matched = 0;
                for _, entry in ipairs(get_entries()) do
                    local label = label_fn(entry);
                    local desc = data.tracker_entry_desc(entry);
                    if (filter_match(label, q) or filter_match(desc, q)) then
                        rows[#rows + 1] = {
                            id = 'entry',
                            label = label,
                            desc = desc,
                            dim = true,
                        };
                        matched = matched + 1;
                    end
                end
                if (matched == 0) then
                    rows[#rows + 1] = {
                        id = '__empty',
                        label = data.tracker_synced()
                            and '(No active entries in this list)'
                            or '(Sync first — Refresh journal)',
                        dim = true,
                        desc = 'Read-only view; names resolve in /tracker when dwtracker data matches.',
                    };
                end
                return rows;
            end,
            on_confirm = function(self, index, n)
                local row = self:rows()[index];
                if (row == nil or row.dim) then
                    if (row ~= nil and row.id == '__refresh') then
                        data.request_tracker_sync(ctx);
                        fire(ctx, cmds.tracker_sync(), 'Queued: !dwt sync');
                    end
                    return;
                end
            end,
        };
    end;
end

function M.quests(ctx)
    local quest_list = read_only_list('Active quests', data.tracker_active_quests, data.tracker_quest_label);
    local mission_list = read_only_list('Active missions', data.tracker_active_missions, data.tracker_mission_label);

    return {
        id = 'quests',
        title = 'Quests',
        rows = action_rows({
            {
                id = 'refresh',
                label = 'Refresh journal',
                desc = 'Pull quest and mission state from the server (!dwt sync).',
                cmd = cmds.tracker_sync(),
            },
            {
                id = 'quest_list',
                label = 'Quest list…',
                desc = 'Browse active quests (read-only).',
            },
            {
                id = 'mission_list',
                label = 'Mission list…',
                desc = 'Browse active missions (read-only).',
            },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then
                return;
            end
            if (row.id == 'refresh') then
                data.request_tracker_sync(ctx);
                if (row.cmd ~= nil) then
                    fire(ctx, row.cmd, 'Queued: ' .. row.cmd);
                end
                return;
            end
            if (row.id == 'quest_list') then
                n:push(quest_list(ctx));
                return;
            end
            if (row.id == 'mission_list') then
                n:push(mission_list(ctx));
            end
        end,
    };
end

return M;
