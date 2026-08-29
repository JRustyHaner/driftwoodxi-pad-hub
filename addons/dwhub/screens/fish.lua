--[[ screens/fish.lua — Progress: fishing guide commands (#47) ]]

local cmds = require('cmds');
local H = require('screens._helpers');

local action_rows = H.action_rows;
local fire = H.fire;

local M = {};

function M.fish(ctx)
    return {
        id = 'fish',
        title = 'Fish',
        rows = action_rows({
            {
                id = 'status',
                label = 'Status',
                desc = 'Skill level, cap, and overview (!fish).',
                cmd = cmds.fish_status(),
            },
            {
                id = 'next',
                label = 'Next catch',
                desc = 'What to fish next for skill-ups (!fish next).',
                cmd = cmds.fish_next(),
            },
            {
                id = 'rank',
                label = 'Rank cap',
                desc = 'Current rank limit and unlocks (!fish rank).',
                cmd = cmds.fish_rank(),
            },
            {
                id = 'route',
                label = 'Full route',
                desc = '0–110 leveling plan (!fish route).',
                cmd = cmds.fish_route(),
            },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row ~= nil and row.cmd ~= nil) then
                fire(ctx, row.cmd, 'Queued: ' .. row.cmd);
            end
        end,
    };
end

return M;
