--[[ screens/rules.lua ]]

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

function M.rules(ctx)
    local function set_pick(on_name)
        data.request_rule_sets(ctx.enqueue);
        data.request_rule_presets(ctx.enqueue);
        return live_pick(ctx, 'Rule set', function()
            local labels = {};
            for _, n in ipairs(data.rule_preset_labels()) do
                labels[#labels + 1] = n;
            end
            for _, n in ipairs(data.rule_set_labels()) do
                labels[#labels + 1] = n;
            end
            return labels;
        end, on_name, {
            refresh = function()
                data.request_rule_sets(ctx.enqueue);
                data.request_rule_presets(ctx.enqueue);
            end,
            refresh_desc = 'Queue !dwg list + !dwg presets.',
            empty = 'No sets — Refresh',
        });
    end

    local function assign_flow(n, with_job)
        n:push(pick_character(ctx, 'Member', { me = true, all = true }, function(member, nav)
            nav:push(set_pick(function(setname, nav2)
                if (with_job) then
                    nav2:push(pick_list('When job', cmds.JOBS, function(job, nav3)
                        fire(ctx, cmds.rules_use_when(member, setname, job), string.format('Rules %s → %s when %s', member, setname, job));
                        nav3:pop(); nav3:pop(); nav3:pop();
                    end));
                else
                    fire(ctx, cmds.rules_use(member, setname), string.format('Rules %s → %s', member, setname));
                    nav2:pop(); nav2:pop();
                end
            end));
        end));
    end

    return {
        id = 'rules',
        title = 'Rules',
        rows = action_rows({
            { id = 'status', label = "What's running", desc = 'Print live rule sets (!squad rules).' },
            { id = 'assign', label = 'Assign set…', desc = 'Member or all → set from list → use.' },
            { id = 'when', label = 'Assign when job…', desc = 'Bind a set to a job on a member.' },
            { id = 'presets', label = 'Refresh shipped presets', desc = '!dwg presets into the pick lists.' },
            { id = 'behavior', label = 'Behavior…', desc = 'Same profiles as Squad behavior.' },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then return; end
            local id = row.id;
            if (id == 'status') then fire(ctx, cmds.rules_status(), 'Rules status → chat.');
            elseif (id == 'assign') then assign_flow(n, false);
            elseif (id == 'when') then assign_flow(n, true);
            elseif (id == 'presets') then
                data.request_rule_presets(ctx.enqueue);
                fire(ctx, cmds.rules_presets(), 'Presets refreshing…');
            elseif (id == 'behavior') then
                n:push(pick_list('Behavior', cmds.BEHAVIORS, function(profile, nav)
                    fire(ctx, cmds.squad_behavior(profile), 'Behavior → ' .. profile);
                    nav:pop();
                end));
            end
        end,
    };
end
return M;
