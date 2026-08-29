--[[ screens/scan.lua — Field: scan target and TH tiers (#46) ]]

local cmds = require('cmds');
local H = require('screens._helpers');

local action_rows = H.action_rows;
local fire = H.fire;
local pick_list = H.pick_list;

local M = {};

local NO_TARGET_MSG = 'No target (<t>) — select a mob first.';

--- True when the player has a main target selected.
function M.has_target()
    if (AshitaCore == nil) then
        return true;
    end
    local mm = AshitaCore:GetMemoryManager();
    if (mm == nil) then
        return false;
    end
    local target = mm:GetTarget();
    if (target == nil) then
        return false;
    end
    local index = target:GetTargetIndex(0);
    return index ~= nil and index ~= 0;
end

local function scan_fire(ctx, command)
    if (not M.has_target()) then
        if (ctx.set_status ~= nil) then
            ctx.set_status(NO_TARGET_MSG);
        end
        return false;
    end
    fire(ctx, command, 'Queued: ' .. command);
    return true;
end

local function th_tier_pick(ctx)
    local tiers = {};
    for tier = 0, 8 do
        tiers[#tiers + 1] = {
            label = string.format('TH%d', tier),
            desc = string.format('Drop rates at Treasure Hunter %d.', tier),
            value = tier,
        };
    end
    return pick_list('Treasure Hunter', tiers, function(tier, n)
        if (scan_fire(ctx, cmds.scan_target(tier))) then
            n:pop();
        end
    end);
end

function M.scan(ctx)
    return {
        id = 'scan',
        title = 'Scan',
        rows = action_rows({
            {
                id = 'scan',
                label = 'Scan target',
                desc = 'Target info and drops for current <t> (!scan).',
            },
            {
                id = 'scan_th',
                label = 'Scan with TH tier…',
                desc = 'Pick Treasure Hunter 0–8 (!scan 0 N).',
            },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then
                return;
            end
            if (row.id == 'scan') then
                scan_fire(ctx, cmds.scan_target());
                return;
            end
            if (row.id == 'scan_th') then
                n:push(th_tier_pick(ctx));
            end
        end,
    };
end

return M;
