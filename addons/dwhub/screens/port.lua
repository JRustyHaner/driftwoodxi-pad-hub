--[[ screens/port.lua ]]

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

function M.port(ctx)
    local function list_go(tab, title, n)
        data.request_port_list(ctx.enqueue, tab);
        local buf = { '' };
        n:push({
            id = 'port-tab:' .. tab,
            title = title,
            search = buf,
            rows = function()
                local q = buf[1] or '';
                local rows = {
                    { id = '__refresh', label = 'Refresh list', desc = 'Queue !port list ' .. tab },
                    { id = '__page2', label = 'Load server page 2', desc = 'Queue !port list ' .. tab .. ' 2' },
                };
                local matched = 0;
                for _, d in ipairs(data.port_entries()) do
                    if (filter_match(d.label, q) or filter_match(d.name or '', q)) then
                        rows[#rows + 1] = {
                            id = 'dest',
                            label = d.label,
                            desc = d.usable and 'Go (unlocked)' or 'Listed (may be locked)',
                            dim = not d.usable,
                            dest = d,
                        };
                        matched = matched + 1;
                    end
                end
                if (matched == 0) then
                    rows[#rows + 1] = {
                        id = '__empty',
                        label = '(No destinations yet — Refresh)',
                        dim = true,
                        desc = 'Refresh after the list arrives in chat.',
                    };
                end
                return rows;
            end,
            on_confirm = function(self, index, nav)
                local row = self:rows()[index];
                if (row == nil) then return; end
                if (row.id == '__refresh') then
                    data.request_port_list(ctx.enqueue, tab);
                    ctx.set_status('Listing ' .. tab .. '…');
                    return;
                end
                if (row.id == '__page2') then
                    data.request_port_list(ctx.enqueue, tab, 2);
                    ctx.set_status('Listing ' .. tab .. ' page 2…');
                    return;
                end
                if (row.id == '__empty') then
                    return;
                end
                if (row.dim) then
                    ctx.set_status('Destination locked — pick another.');
                    return;
                end
                local dest = row.dest;
                local key = dest.id or dest.name;
                fire(ctx, cmds.port_go(tab, key), 'Go ' .. (dest.name or key));
                data.end_port_list();
                nav:pop();
            end,
        });
    end

    return {
        id = 'port',
        title = 'Port',
        rows = action_rows({
            { id = 'home', label = 'Home nation', desc = 'Free nation home (!port home).' },
            { id = 'hp', label = 'Home points…', desc = 'List / go home points.' },
            { id = 'sg', label = 'Survival guides…', desc = 'List / go survival guides.' },
            { id = 'op', label = 'Outposts…', desc = 'List / go outposts.' },
            { id = 'sp', label = 'Teleport spells…', desc = 'List / go teleport spells.' },
            { id = 'search', label = 'Search…', desc = 'Type unambiguous zone/crystal name.' },
        }),
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then return; end
            local id = row.id;
            if (id == 'home') then fire(ctx, cmds.port_home(), 'Port home.');
            elseif (id == 'hp') then list_go('hp', 'Home points', n);
            elseif (id == 'sg') then list_go('sg', 'Survival guides', n);
            elseif (id == 'op') then list_go('op', 'Outposts', n);
            elseif (id == 'sp') then list_go('sp', 'Teleport spells', n);
            elseif (id == 'search') then
                n:push(text_entry('Destination name', 'Unambiguous zone/crystal name.', '', function(name, nav)
                    fire(ctx, cmds.port_name(name), 'Port ' .. name);
                    nav:pop();
                end));
            end
        end,
    };
end
return M;
