--[[ screens/raid.lua — Instances: raid trials enter/leave (#49) ]]

local cmds = require('cmds');
local H = require('screens._helpers');

local action_rows = H.action_rows;
local fire = H.fire;
local pick_list = H.pick_list;
local confirm_pick = H.confirm_pick;

local M = {};

local function title_slug(slug)
    if (slug == nil or slug == '') then
        return slug;
    end
    return slug:sub(1, 1):upper() .. slug:sub(2);
end

local function tier_pick(ctx, boss)
    local tiers = {};
    for _, tier in ipairs(cmds.RAID_TIERS) do
        tiers[#tiers + 1] = {
            label = title_slug(tier),
            desc = string.format('Enter %s at %s difficulty.', title_slug(boss), tier),
            value = tier,
        };
    end
    return pick_list('Difficulty', tiers, function(tier, nav)
        local command = cmds.raid_enter(boss, tier);
        nav:push(confirm_pick(
            'Enter trial',
            string.format('Warp party into %s (%s).', title_slug(boss), tier),
            function(nav2)
                fire(ctx, command, 'Queued: ' .. command);
                nav2:pop();
                nav2:pop();
                nav2:pop();
            end
        ));
    end);
end

local function boss_pick(ctx)
    local bosses = {};
    for _, boss in ipairs(cmds.RAID_BOSSES) do
        bosses[#bosses + 1] = {
            label = title_slug(boss),
            desc = string.format('Pick difficulty for %s.', title_slug(boss)),
            value = boss,
        };
    end
    return pick_list('Boss trial', bosses, function(boss, nav)
        nav:push(tier_pick(ctx, boss));
    end);
end

function M.raid(ctx)
    return {
        id = 'raid',
        title = 'Raid',
        rows = action_rows({
            {
                id = 'board',
                label = 'Board',
                desc = 'Trials, tiers, purse, and arenas (!raid).',
                cmd = cmds.raid_board(),
            },
            {
                id = 'enter',
                label = 'Enter trial…',
                desc = 'Pick boss and difficulty (!raid enter).',
            },
            {
                id = 'leave',
                label = 'Leave',
                desc = 'Exit the arena back to your tile (!raid leave).',
                cmd = cmds.raid_leave(),
            },
            {
                id = 'marks',
                label = 'Driftmarks',
                desc = 'Account purse and balance (!raid marks).',
                cmd = cmds.raid_marks(),
            },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then
                return;
            end
            if (row.id == 'enter') then
                n:push(boss_pick(ctx));
                return;
            end
            if (row.cmd ~= nil) then
                fire(ctx, row.cmd, 'Queued: ' .. row.cmd);
            end
        end,
    };
end

return M;
