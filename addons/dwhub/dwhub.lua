--[[
* DriftwoodXI — dwhub
*
* Controller-first hub overlay. Issues the same typed ! commands the official
* Driftwood windows use.
*
* Nav shell: Home categories with placeholder category screens.
--]]

addon.name    = 'dwhub';
addon.author  = 'DriftwoodXI Pad Hub';
addon.version = '0.2.0';
addon.desc    = 'Pad-first DriftwoodXI hub (squad, jobs, items, rules, port).';
addon.link    = 'https://github.com/JRustyHaner/driftwoodxi-pad-hub';

require('common');

local chat  = require('chat');
local imgui = require('imgui');
local theme = require('theme');
local navmod = require('nav');
local screens = require('screens');
local queue_mod = require('queue');
local input = require('input');

local state = {
    open = { false },
};

local nav = navmod.new();
local cmd_queue = queue_mod.new({
    interval = 1.2,
});

local function live_send(command)
    AshitaCore:GetChatManager():QueueCommand(1, command);
end

cmd_queue:set_send(live_send);

local function open_category(name, n)
    n:push(screens.placeholder(name, 'Screen scaffolding — commands arrive in feature PRs.'));
end

local function ensure_root()
    if (nav:depth() == 0) then
        nav:reset(screens.home(nav, open_category));
    end
end

local function set_open(value)
    state.open[1] = value and true or false;
    if (state.open[1]) then
        ensure_root();
        input.capture(true);
    else
        input.capture(false);
        cmd_queue:clear();
        nav:reset(nil);
    end
end

local function toggle()
    set_open(not state.open[1]);
end

local function key_pressed(key)
    -- Ashita ImGui binding: IsKeyPressed if available
    if (imgui.IsKeyPressed ~= nil) then
        return imgui.IsKeyPressed(key);
    end
    return false;
end

local function handle_input()
    if (key_pressed(ImGuiKey_UpArrow) or key_pressed(ImGuiKey_GamepadDpadUp)) then
        nav:move(-1);
    end
    if (key_pressed(ImGuiKey_DownArrow) or key_pressed(ImGuiKey_GamepadDpadDown)) then
        nav:move(1);
    end
    if (key_pressed(ImGuiKey_Enter) or key_pressed(ImGuiKey_GamepadFaceDown)) then
        nav:confirm();
    end
    if (key_pressed(ImGuiKey_Escape) or key_pressed(ImGuiKey_GamepadFaceRight)) then
        local result = nav:back();
        if (result == 'close') then
            set_open(false);
        end
    end
end

local function draw_description()
    local title = 'Category Selection';
    local cur = nav:current();
    if (cur ~= nil and cur.title ~= nil) then
        title = cur.title;
    end
    imgui.TextColored(theme.colors.title, title);
    imgui.Spacing();
    imgui.TextWrapped(nav:description());
    if (nav.status ~= nil and nav.status ~= '') then
        imgui.Spacing();
        imgui.TextColored(theme.colors.textDim, nav.status);
    end
end

local function draw_list()
    local cur = nav:current();
    if (cur == nil) then
        return;
    end
    local rows = cur:rows();
    for i = 1, #rows do
        local row = rows[i];
        local focused = (i == nav.focus);
        local label = row.label or '?';
        if (focused) then
            label = '> ' .. label;
            local col = row.dim and theme.colors.textDim or theme.colors.selection;
            imgui.TextColored(col, label);
        else
            local col = row.dim and theme.colors.textDim or theme.colors.text;
            imgui.TextColored(col, '  ' .. (row.label or '?'));
        end
    end
end

local function draw_window()
    imgui.SetNextWindowSize({ 520, 360 }, ImGuiCond_FirstUseEver);
    imgui.SetNextWindowPos({ 40, 60 }, ImGuiCond_FirstUseEver);

    local visible = imgui.Begin('DriftwoodXI Pad Hub##dwhub', state.open, bit.bor(ImGuiWindowFlags_NoCollapse, ImGuiWindowFlags_NoScrollbar));
    if (visible) then
        handle_input();

        -- Description panel (top) — OSK-safe region for future search
        draw_description();
        imgui.Separator();
        draw_list();
        imgui.Separator();
        local footer = (nav:depth() <= 1) and 'A Confirm   B Close' or 'A Confirm   B Back';
        imgui.TextColored(theme.colors.textDim, footer);
        if (cmd_queue:len() > 0) then
            imgui.SameLine();
            imgui.TextColored(theme.colors.textDim, string.format('  queue:%d', cmd_queue:len()));
        end
    end
    imgui.End();

    if (not state.open[1]) then
        nav:reset(nil);
    end
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
    cmd_queue:tick();

    if (not state.open[1]) then
        return;
    end

    ensure_root();

    local token = theme.push();
    local ok, err = pcall(draw_window);
    theme.pop(token);
    if (not ok) then
        print(chat.header('dwhub'):append(chat.error(tostring(err))));
    end
end);

ashita.events.register('load', 'dwhub_load', function ()
    print(chat.header('dwhub'):append(chat.message('/dwhub (or /hub) toggles the pad hub. D-pad / arrows move, A/Enter confirm, B/Esc back.')));
end);

return {
    state = state,
    set_open = set_open,
    toggle = toggle,
    nav = nav,
    queue = cmd_queue,
};
