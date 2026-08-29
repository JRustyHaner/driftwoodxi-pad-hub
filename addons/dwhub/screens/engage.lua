--[[ screens/engage.lua — Field: auto-target and trust engage (#45) ]]

local cmds = require('cmds');
local H = require('screens._helpers');

local action_rows = H.action_rows;
local fire = H.fire;
local pick_list = H.pick_list;

local M = {};

local function auto_target_pick(ctx)
    return pick_list('Auto-target', { 'On', 'Off' }, function(label, n)
        local command = (label == 'On') and cmds.dwengage_on() or cmds.dwengage_off();
        fire(ctx, command, 'Queued: ' .. command);
        n:pop();
    end);
end

function M.engage(ctx)
    return {
        id = 'engage',
        title = 'Engage',
        rows = action_rows({
            {
                id = 'autotarget',
                label = 'Auto-target next mob',
                desc = 'Spin to next party target (/dwengage on or off).',
            },
            {
                id = 'retail',
                label = 'Trust engage: Retail',
                desc = 'Master swings first.',
                cmd = cmds.trustengage_mode(0),
            },
            {
                id = 'attack',
                label = 'Trust engage: Attack',
                desc = 'Trusts commit when you engage.',
                cmd = cmds.trustengage_mode(1),
            },
            {
                id = 'show',
                label = 'Show trust setting',
                desc = 'Print current !trustengage mode in chat.',
                cmd = cmds.trustengage_status(),
            },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then
                return;
            end
            if (row.id == 'autotarget') then
                n:push(auto_target_pick(ctx));
                return;
            end
            if (row.cmd ~= nil) then
                fire(ctx, row.cmd, 'Queued: ' .. row.cmd);
            end
        end,
    };
end

return M;
