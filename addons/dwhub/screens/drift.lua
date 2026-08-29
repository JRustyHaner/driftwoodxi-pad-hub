--[[ screens/drift.lua — Progress: Drift Board + shops (#51, #52) ]]

local cmds = require('cmds');
local H = require('screens._helpers');

local action_rows = H.action_rows;
local fire = H.fire;
local pick_list = H.pick_list;
local confirm_pick = H.confirm_pick;
local text_entry = H.text_entry;

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

local function augment_slot_pick(ctx)
    local offers = {};
    for _, slot in ipairs(cmds.DRIFT_AUGMENT_SLOTS) do
        offers[#offers + 1] = {
            label = string.upper(slot),
            desc = 'Price this augment offer.',
            value = slot,
        };
    end
    return pick_list('Augment offer', offers, function(slot, nav)
        local price_cmd = cmds.drift_augment_price(slot);
        fire(ctx, price_cmd, 'Queued: ' .. price_cmd);
        nav:push(confirm_pick(
            'Buy augment',
            string.format('Spend Drift Coins on %s?', string.upper(slot)),
            function(nav2)
                fire(ctx, cmds.drift_confirm(), 'Queued: !drift confirm');
                nav2:pop();
                nav2:pop();
            end
        ));
    end);
end

local function augments_menu(ctx)
    return pick_list('Augments', { 'View offers', 'Buy…' }, function(action, nav)
        if (action == 'View offers') then
            fire(ctx, cmds.drift_augments(), 'Queued: !drift augments');
            nav:pop();
            return;
        end
        nav:push(augment_slot_pick(ctx));
    end);
end

local function outfitter_buy(ctx, job)
    return text_entry(
        'Shelf item #',
        'Item id from the !drift shelf output.',
        '',
        function(text, nav)
            local item_id = tonumber(text);
            if (item_id == nil or item_id <= 0) then
                return;
            end
            local buy_cmd = cmds.drift_buy(item_id);
            fire(ctx, buy_cmd, 'Queued: ' .. buy_cmd);
            nav:push(confirm_pick(
                'Buy gear',
                string.format('Confirm purchase of item %d (%s)?', item_id, job),
                function(nav2)
                    fire(ctx, cmds.drift_confirm(), 'Queued: !drift confirm');
                    nav2:pop();
                    nav2:pop();
                    nav2:pop();
                end
            ));
        end
    );
end

local function outfitter_job_pick(ctx)
    local jobs = {};
    for _, job in ipairs(cmds.JOBS) do
        jobs[#jobs + 1] = {
            label = job,
            desc = 'Artifact (25 DC) and relic (125 DC) sets.',
            value = job,
        };
    end
    return pick_list('Outfitter job', jobs, function(job, nav)
        local shelf_cmd = cmds.drift_shelf(job);
        fire(ctx, shelf_cmd, 'Queued: ' .. shelf_cmd);
        nav:push(outfitter_buy(ctx, job));
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
            {
                id = 'augments',
                label = 'Augments…',
                desc = 'View offers or buy with !drift confirm.',
            },
            {
                id = 'outfitter',
                label = 'Outfitter…',
                desc = 'Job shelf, item id, buy, and confirm.',
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
            if (row.id == 'augments') then
                n:push(augments_menu(ctx));
                return;
            end
            if (row.id == 'outfitter') then
                n:push(outfitter_job_pick(ctx));
                return;
            end
            if (row.cmd ~= nil) then
                fire(ctx, row.cmd, 'Queued: ' .. row.cmd);
            end
        end,
    };
end

return M;
