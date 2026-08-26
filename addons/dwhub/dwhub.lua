--[[
* DriftwoodXI — dwhub
*
* Controller-first hub overlay. Issues the same typed ! commands the official
* Driftwood windows use. This file is the addon entry: load, toggle, present.
*
* Scaffold: empty themed window only. No ! commands yet.
--]]

addon.name    = 'dwhub';
addon.author  = 'DriftwoodXI Pad Hub';
addon.version = '0.1.0';
addon.desc    = 'Pad-first DriftwoodXI hub (squad, jobs, items, rules, port).';
addon.link    = 'https://github.com/JRustyHaner/driftwoodxi-pad-hub';

require('common');

local chat  = require('chat');
local imgui = require('imgui');
local theme = require('theme');

local state = {
    open = { false },
};

local function set_open(value)
    state.open[1] = value and true or false;
end

local function toggle()
    set_open(not state.open[1]);
end

local function draw_window()
    imgui.SetNextWindowSize({ 420, 280 }, ImGuiCond_FirstUseEver);
    imgui.SetNextWindowPos({ 40, 80 }, ImGuiCond_FirstUseEver);

    local visible = imgui.Begin('DriftwoodXI Pad Hub##dwhub', state.open, ImGuiWindowFlags_NoCollapse);
    if (visible) then
        imgui.TextColored(theme.colors.title, 'Pad Hub');
        imgui.Separator();
        imgui.TextWrapped('Scaffold window. Navigation and commands land in follow-up PRs.');
        imgui.Spacing();
        imgui.TextColored(theme.colors.textDim, 'Toggle: /dwhub or /hub');
        imgui.TextColored(theme.colors.textDim, 'A Confirm   B Back (coming soon)');
    end
    imgui.End();
end

ashita.events.register('command', 'dwhub_command', function (e)
    local args = e.command:args();
    if (#args == 0) then
        return;
    end

    local cmd = string.lower(args[1]);
    if (cmd ~= '/dwhub' and cmd ~= '/hub') then
        return;
    end

    e.blocked = true;

    if (#args >= 2) then
        local sub = string.lower(args[2]);
        if (sub == 'open' or sub == 'show' or sub == 'on') then
            set_open(true);
            return;
        end
        if (sub == 'close' or sub == 'hide' or sub == 'off') then
            set_open(false);
            return;
        end
        if (sub == 'toggle') then
            toggle();
            return;
        end
    end

    toggle();
end);

ashita.events.register('d3d_present', 'dwhub_present', function ()
    if (not state.open[1]) then
        return;
    end

    local token = theme.push();
    local ok, err = pcall(draw_window);
    theme.pop(token);
    if (not ok) then
        print(chat.header('dwhub'):append(chat.error(tostring(err))));
    end
end);

ashita.events.register('load', 'dwhub_load', function ()
    print(chat.header('dwhub'):append(chat.message('/dwhub (or /hub) toggles the pad hub window.')));
end);

-- Exported for later modules / tests
return {
    state = state,
    set_open = set_open,
    toggle = toggle,
};
