--[[ screens/squad.lua ]]

local cmds = require('cmds');
local data = require('data');
local H = require('screens._helpers');

local action_rows = H.action_rows;
local fire = H.fire;
local filter_match = H.filter_match;
local pick_list = H.pick_list;
local pick_rows = H.pick_rows;
local qty_pick = H.qty_pick;
local text_entry = H.text_entry;
local live_pick = H.live_pick;
local pick_character = H.pick_character;
local cast_member_flow = H.cast_member_flow;
local cast_all_flow = H.cast_all_flow;
local pop_to_category = H.pop_to_category;

local M = {};

function M.squad(ctx)
    local function behavior_menu(n)
        n:push(pick_list('Behavior', cmds.BEHAVIORS, function(profile, nav)
            fire(ctx, cmds.squad_behavior(profile), 'Behavior → ' .. profile);
            nav:pop();
        end));
    end

    local function clear_slot_menu(n)
        n:push(pick_list('Clear slot', { '1', '2', '3', '4', '5' }, function(slot, nav)
            fire(ctx, cmds.squad_clear(tonumber(slot)), 'Clear slot ' .. slot);
            nav:pop();
        end));
    end

    local function set_slot_menu(n)
        n:push(pick_list('Set slot', { '1', '2', '3', '4', '5' }, function(slot, nav)
            nav:push(pick_character(ctx, 'Character for slot ' .. slot, { me = false }, function(name, nav2)
                fire(ctx, cmds.squad_set(tonumber(slot), name), string.format('Set %s → slot %s', name, slot));
                nav2:pop();
                nav2:pop();
            end));
        end));
    end

    local function squad_roster_screen()
        return {
            id = 'squad:roster',
            title = 'Squad roster',
            rows = function()
                local rows = {
                    { id = '__refresh', label = 'Refresh roster', desc = 'Queue !dws who + !squad list' },
                };
                for _, row in ipairs(data.squad_slot_rows()) do
                    rows[#rows + 1] = row;
                end
                return rows;
            end,
            on_confirm = function(self, index, n)
                local row = self:rows()[index];
                if (row == nil) then
                    return;
                end
                if (row.id == '__refresh') then
                    data.request_roster(ctx);
                    fire(ctx, cmds.squad_list(), 'Refreshing roster…');
                    return;
                end
            end,
        };
    end

    local function hints_flow(n, char)
        data.request_roster(ctx);
        fire(ctx, cmds.squad_hints(char), 'Hints → chat.');
        n:pop();
    end

    local function hints_menu(n)
        n:push(pick_character(ctx, 'Hints for', { me = true }, function(name, nav)
            hints_flow(nav, name);
        end));
    end

    return {
        id = 'squad',
        title = 'Squad',
        rows = action_rows({
            { id = 'call', label = 'Call', desc = 'Summon registered squad members (!squad call).' },
            { id = 'dismiss', label = 'Dismiss', desc = 'Send the squad home (!squad dismiss).' },
            { id = 'list', label = 'Roster', desc = 'Read-only squad slots 1–5.' },
            { id = 'set', label = 'Set slot…', desc = 'Register a character to a squad slot.' },
            { id = 'clear', label = 'Clear slot…', desc = 'Un-register a slot.' },
            { id = 'engage', label = 'Engage', desc = 'All onto your current target.' },
            { id = 'disengage', label = 'Disengage', desc = 'All stand down and stay down.' },
            { id = 'come', label = 'Come', desc = 'Regroup on you.' },
            { id = 'rest', label = 'Rest', desc = 'Stand down and recover HP/MP.' },
            { id = 'cast', label = 'Cast…', desc = 'Job tag → spell → target (!whm cure3 me).' },
            { id = 'castall', label = 'Cast all…', desc = 'Every member of a job (!allwhm curaga me).' },
            { id = 'behavior', label = 'Behavior…', desc = 'Aggressive / defensive / passive / off.' },
            { id = 'hints_me', label = 'Hints (me)', desc = 'Gear upgrades for logged-in character (!squad hints me).' },
            { id = 'hints', label = 'Hints…', desc = 'Pick member → what would make them stronger (!squad hints).' },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then
                return;
            end
            local id = row.id;
            if (id == 'call') then fire(ctx, cmds.squad_call(), 'Calling squad…');
            elseif (id == 'dismiss') then fire(ctx, cmds.squad_dismiss(), 'Dismissing…');
            elseif (id == 'list') then
                n:push(squad_roster_screen());
            elseif (id == 'set') then set_slot_menu(n);
            elseif (id == 'clear') then clear_slot_menu(n);
            elseif (id == 'engage') then fire(ctx, cmds.squad_engage(), 'Engage.');
            elseif (id == 'disengage') then fire(ctx, cmds.squad_disengage(), 'Disengage.');
            elseif (id == 'come') then fire(ctx, cmds.squad_come(), 'Come.');
            elseif (id == 'rest') then fire(ctx, cmds.squad_rest(), 'Rest.');
            elseif (id == 'cast') then cast_member_flow(ctx, n);
            elseif (id == 'castall') then cast_all_flow(ctx, n);
            elseif (id == 'behavior') then behavior_menu(n);
            elseif (id == 'hints_me') then fire(ctx, cmds.squad_hints('me'), 'Hints (me) → chat.');
            elseif (id == 'hints') then hints_menu(n);
            end
        end,
    };
end
return M;
