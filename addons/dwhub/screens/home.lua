--[[ screens/home.lua — Home groups and group menus ]]

local H = require('screens._helpers');
local action_rows = H.action_rows;

local M = {};

function M.placeholder(title, blurb)
    return {
        id = 'placeholder:' .. title,
        title = title,
        rows = function()
            return {
                { label = '(Coming in a follow-up PR)', dim = true, desc = blurb or 'Not implemented yet.' },
            };
        end,
        on_confirm = function() end,
    };
end

--- Fixed Home groups (MENU-IA). Home never grows beyond these five rows.
M.HOME_GROUPS = {
    {
        id = 'party',
        label = 'Party and Travel',
        desc = 'Squad, jobs, combat rules, and teleport.',
        categories = {
            { label = 'Squad', category = 'Squad', desc = 'Call, dismiss, slots, field orders, behavior.' },
            { label = 'Jobs', category = 'Jobs', desc = 'Change main/sub jobs or use lineup presets.' },
            { label = 'Rules', category = 'Rules', desc = 'Assign gambit presets to squad members.' },
            { label = 'Port', category = 'Port', desc = 'Home points, guides, outposts, teleport spells.' },
        },
    },
    {
        id = 'inventory',
        label = 'Inventory and Trade',
        desc = 'Account bags, gear, and economy.',
        categories = {
            { label = 'Items', category = 'Items', desc = 'Find, send, fetch, and equip across your account.' },
            { label = 'Storage', category = 'Storage', desc = 'Account warehouse (!warehouse).' },
            { label = 'Market', category = 'Market', desc = 'Player market (!market).' },
            { label = 'Merc', category = 'Merc', desc = 'Mercenary board (!merc).' },
        },
    },
    {
        id = 'quests',
        label = 'Quests and Crafts',
        desc = 'Journal, contracts, and skilling.',
        categories = {
            { label = 'Quests', category = 'Quests', desc = 'Quest journal (!dwt sync).' },
            { label = 'Drift', category = 'Drift', desc = 'Drift Board contracts (!drift).' },
            { label = 'Fish', category = 'Fish', desc = 'Fishing guide (!fish).' },
            { label = 'Craft', desc = 'Crafting ledger — coming soon.', dim = true },
        },
    },
    {
        id = 'instances',
        label = 'Instances',
        desc = 'Raids and Gauntlet from anywhere.',
        categories = {
            { label = 'Raid', category = 'Raid', desc = 'Boss trials (!raid).' },
            { label = 'Arena', category = 'Arena', desc = 'Gauntlet waves (!arena).' },
        },
    },
    {
        id = 'field',
        label = 'Field',
        desc = 'Target info and engage helpers.',
        categories = {
            { label = 'Scan', category = 'Scan', desc = 'Scan target (!scan).' },
            { label = 'Engage', category = 'Engage', desc = 'Trust engage and auto-target.' },
        },
    },
};
function M.group(group_def, open_category)
    local title = group_def.label or 'Group';
    local entries = group_def.categories or {};
    return {
        id = 'group:' .. (group_def.id or title),
        title = title,
        rows = action_rows(entries),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil or row.dim) then
                if (row ~= nil and n.status ~= nil) then
                    n.status = row.desc or 'Coming soon.';
                end
                return;
            end
            local cat = entries[index] and entries[index].category;
            if (cat == nil) then
                return;
            end
            if (open_category ~= nil) then
                open_category(cat, n);
            end
        end,
    };
end

function M.home(open_group)
    return {
        id = 'home',
        title = 'Pad Hub',
        rows = function()
            local rows = {};
            for i, g in ipairs(M.HOME_GROUPS) do
                rows[i] = {
                    id = g.id,
                    label = g.label,
                    desc = g.desc,
                };
            end
            return rows;
        end,
        on_confirm = function(self, index, n)
            local g = M.HOME_GROUPS[index];
            if (g == nil) then
                return;
            end
            if (open_group ~= nil) then
                open_group(g, n);
            end
        end,
        on_back = function()
            return 'close';
        end,
    };
end

return M;
