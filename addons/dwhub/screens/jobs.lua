--[[ screens/jobs.lua ]]

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

function M.jobs(ctx)
    local function change_jobs(n)
        n:push(pick_character(ctx, 'Character', { me = true }, function(char, nav)
            data.request_jobs(ctx.enqueue);
            nav:push(pick_rows('Main job', function()
                return data.job_pick_rows(char, { include_none = false });
            end, function(main, nav2)
                nav2:push(pick_rows('Sub job', function()
                    return data.job_pick_rows(char, { include_none = true });
                end, function(sub, nav3)
                    fire(ctx, cmds.jobs_set(char, main, sub), string.format('Jobs %s → %s/%s', char, main, sub));
                    nav3:pop();
                    nav3:pop();
                    nav3:pop();
                end));
            end));
        end));
    end

    local function preset_pick(title, on_name)
        data.request_jobs(ctx.enqueue);
        data.request_job_presets(ctx.enqueue);
        return live_pick(ctx, title, function()
            return data.job_preset_labels();
        end, on_name, {
            refresh = function()
                data.request_job_presets(ctx.enqueue);
            end,
            refresh_desc = 'Queue !dwj list.',
            empty = 'No presets — Refresh',
        });
    end

    return {
        id = 'jobs',
        title = 'Jobs',
        rows = action_rows({
            { id = 'change', label = 'Change jobs…', desc = 'Pick character, then main and sub from the full job list.' },
            { id = 'use', label = 'Use preset…', desc = 'Apply a saved lineup (!jobs use).' },
            { id = 'save', label = 'Save preset…', desc = 'Save current lineup (!jobs save).' },
            { id = 'delete', label = 'Delete preset…', desc = 'Delete a saved lineup (!jobs delete).' },
            { id = 'list', label = 'List presets', desc = 'Refresh preset list from server.' },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then
                return;
            end
            local id = row.id;
            if (id == 'change') then
                change_jobs(n);
            elseif (id == 'use') then
                n:push(preset_pick('Use preset', function(name, nav)
                    fire(ctx, cmds.jobs_use(name), 'Use preset ' .. name);
                    nav:pop();
                end));
            elseif (id == 'save') then
                n:push(text_entry('Preset name', 'Name to save as.', '', function(name, nav)
                    fire(ctx, cmds.jobs_save(name), 'Save preset ' .. name);
                    nav:pop();
                end));
            elseif (id == 'delete') then
                n:push(preset_pick('Delete preset', function(name, nav)
                    fire(ctx, cmds.jobs_delete(name), 'Delete preset ' .. name);
                    nav:pop();
                end));
            elseif (id == 'list') then
                data.request_job_presets(ctx.enqueue);
                fire(ctx, cmds.jobs_list(), 'Presets refreshing…');
            end
        end,
    };
end
return M;
