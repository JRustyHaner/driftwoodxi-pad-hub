--[[ screens/drift.lua — Progress: Drift Board contracts (#51) ]]

local cmds = require('cmds');
local H = require('screens._helpers');

local action_rows = H.action_rows;
local fire = H.fire;
local pick_list = H.pick_list;
local confirm_pick = H.confirm_pick;

local M = {};

local SLOT_LABELS = {
    d1 = 'Daily 1',
    d2 = 'Daily 2',
    d3 = 'Daily 3',
    d4 = 'Daily 4',
    w1 = 'Weekly 1',
    w2 = 'Weekly 2',
    w3 = 'Weekly 3',
    w4 = 'Weekly 4',
};

local function slot_label(slot)
    return SLOT_LABELS[slot] or slot;
end

local function action_pick(ctx, slot)
    return pick_list(slot_label(slot), { 'Accept', 'Abandon' }, function(action, nav)
        if (action == 'Accept') then
            local command = cmds.drift_accept(slot);
            fire(ctx, command, 'Queued: ' .. command);
            nav:pop();
            nav:pop();
            return;
        end
        nav:push(confirm_pick(
            'Abandon contract',
            string.format('Give up %s (%s)?', slot_label(slot), slot),
            function(nav2)
                local command = cmds.drift_abandon(slot);
                fire(ctx, command, 'Queued: ' .. command);
                nav2:pop();
                nav2:pop();
                nav2:pop();
            end
        ));
    end);
end

local function contract_pick(ctx)
    local slots = {};
    for _, slot in ipairs(cmds.DRIFT_SLOTS) do
        slots[#slots + 1] = {
            label = slot_label(slot),
            desc = string.format('Contract slot %s', slot),
            value = slot,
        };
    end
    return pick_list('Drift contract', slots, function(slot, nav)
        nav:push(action_pick(ctx, slot));
    end);
end

function M.drift(ctx)
    return {
        id = 'drift',
        title = 'Drift',
        rows = action_rows({
            {
                id = 'board',
                label = 'Board',
                desc = 'Daily and weekly contracts for your level (!drift).',
                cmd = cmds.drift_board(),
            },
            {
                id = 'contracts',
                label = 'Accept / abandon…',
                desc = 'Pick d1–d4 or w1–w4, then accept or abandon.',
            },
            {
                id = 'balance',
                label = 'Balance',
                desc = 'Drift Coins and recent ledger (!drift balance).',
                cmd = cmds.drift_balance(),
            },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then
                return;
            end
            if (row.id == 'contracts') then
                n:push(contract_pick(ctx));
                return;
            end
            if (row.cmd ~= nil) then
                fire(ctx, row.cmd, 'Queued: ' .. row.cmd);
            end
        end,
    };
end

return M;
