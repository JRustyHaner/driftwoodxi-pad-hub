--[[ screens/arena.lua — Instances: Gauntlet enter/leave (#48) ]]

local cmds = require('cmds');
local H = require('screens._helpers');

local action_rows = H.action_rows;
local fire = H.fire;
local confirm_pick = H.confirm_pick;

local M = {};

function M.arena(ctx)
    return {
        id = 'arena',
        title = 'Arena',
        rows = action_rows({
            {
                id = 'status',
                label = 'Status',
                desc = 'Gauntlet progress and party state (!arena).',
                cmd = cmds.arena_board(),
            },
            {
                id = 'enter',
                label = 'Enter group',
                desc = 'Warp party into the Gauntlet (!arena enter).',
            },
            {
                id = 'leave',
                label = 'Leave',
                desc = 'Exit the Gauntlet instance (!arena leave).',
                cmd = cmds.arena_leave(),
            },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then
                return;
            end
            if (row.id == 'enter') then
                n:push(confirm_pick(
                    'Enter Gauntlet',
                    'Warp your party into the Arena Gauntlet.',
                    function(nav2)
                        fire(ctx, cmds.arena_enter(), 'Queued: !arena enter');
                        nav2:pop();
                    end
                ));
                return;
            end
            if (row.cmd ~= nil) then
                fire(ctx, row.cmd, 'Queued: ' .. row.cmd);
            end
        end,
    };
end

return M;
