--[[ screens/raid.lua — Instances: raid trials + shop (#49, #58) ]]

local cmds = require('cmds');
local H = require('screens._helpers');

local action_rows = H.action_rows;
local fire = H.fire;
local pick_list = H.pick_list;
local confirm_pick = H.confirm_pick;
local text_entry = H.text_entry;

local M = {};

local function title_slug(slug)
    if (slug == nil or slug == '') then
        return slug;
    end
    return slug:sub(1, 1):upper() .. slug:sub(2);
end

local function trim(text)
    return (text or ''):gsub('^%s+', ''):gsub('%s+$', '');
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

local function shop_tab_pick(ctx)
    local tabs = {};
    for _, tab in ipairs(cmds.RAID_SHOP_TABS) do
        tabs[#tabs + 1] = {
            label = title_slug(tab),
            desc = string.format('Browse %s (!raid shop %s).', tab, tab),
            value = tab,
        };
    end
    return pick_list('Shop tab', tabs, function(tab, nav)
        fire(ctx, cmds.raid_shop(tab), 'Queued: ' .. cmds.raid_shop(tab));
        nav:push(text_entry(
            'Shop item #',
            'Item id or tag from the !raid shop output.',
            '',
            function(text, nav2)
                local item = trim(text);
                if (item == '') then
                    return;
                end
                local buy_cmd = cmds.raid_buy(item);
                fire(ctx, buy_cmd, 'Queued: ' .. buy_cmd);
                nav2:push(confirm_pick(
                    'Buy raid gear',
                    string.format('Spend Driftmarks on %s (%s tab)?', item, tab),
                    function(nav3)
                        fire(ctx, cmds.raid_confirm(), 'Queued: !raid confirm');
                        nav3:pop();
                        nav3:pop();
                        nav3:pop();
                    end
                ));
            end
        ));
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
            {
                id = 'shop',
                label = 'Shop…',
                desc = 'Supplies and gear tabs, buy with confirm.',
            },
            {
                id = 'reforge',
                label = 'Reforge',
                desc = 'Upgrade relic armor (!raid reforge).',
                cmd = cmds.raid_reforge(),
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
            if (row.id == 'shop') then
                n:push(shop_tab_pick(ctx));
                return;
            end
            if (row.cmd ~= nil) then
                fire(ctx, row.cmd, 'Queued: ' .. row.cmd);
            end
        end,
    };
end

return M;
