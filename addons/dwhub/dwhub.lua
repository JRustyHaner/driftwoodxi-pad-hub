--[[
* DriftwoodXI — dwhub
*
* Controller-first hub overlay. Issues the same typed ! commands the official
* Driftwood windows use.
*
* Nav shell: Home → group → category (see docs/MENU-IA.md).
--]]

addon.name    = 'dwhub';
addon.author  = 'DriftwoodXI Pad Hub';
addon.version = '0.6.1';
addon.desc    = 'Pad-first DriftwoodXI hub — Party, Inventory, Quests, Instances, Field.';
addon.link    = 'https://github.com/JRustyHaner/driftwoodxi-pad-hub';

require('common');

local chat  = require('chat');
local imgui = require('imgui');
local theme = require('theme');
local scale_mod = require('scale');
local layout = require('layout');
local navmod = require('nav');
local screens = require('screens');
local queue_mod = require('queue');
local input = require('input');
local pad = require('pad');
local data = require('data');

local state = {
    open = { false },
    focus_once = false,
    search_focus = false,
    last_screen_id = nil,
    last_list_sig = nil,
};

local nav = navmod.new();
local cmd_queue = queue_mod.new({
    interval = 1.2,
});

--- Inject one outgoing line (Typed — same as official dw* addons).
--- Unknown ! verbs on Driftwood fall through to public /say; only send registered commands.
local function live_send(command)
    AshitaCore:GetChatManager():QueueCommand(1, command);
end

cmd_queue:set_send(live_send);

local function make_ctx()
    return {
        enqueue = function(command)
            cmd_queue:enqueue(command);
        end,
        set_status = function(msg)
            nav.status = msg or '';
        end,
    };
end

local CATEGORY_SCREENS = {
    Squad = function(ctx) return screens.squad(ctx); end,
    Jobs = function(ctx) return screens.jobs(ctx); end,
    Rules = function(ctx) return screens.rules(ctx); end,
    Port = function(ctx) return screens.port(ctx); end,
    Items = function(ctx) return screens.items(ctx); end,
    Storage = function(ctx) return screens.storage(ctx); end,
    Market = function(ctx) return screens.market(ctx); end,
    Merc = function(ctx) return screens.merc(ctx); end,
    Quests = function(ctx) return screens.quests(ctx); end,
    Drift = function(ctx) return screens.drift(ctx); end,
    Fish = function(ctx) return screens.fish(ctx); end,
    Raid = function(ctx) return screens.raid(ctx); end,
    Arena = function(ctx) return screens.arena(ctx); end,
    Scan = function(ctx) return screens.scan(ctx); end,
    Engage = function(ctx) return screens.engage(ctx); end,
};

local function open_category(name, n)
    local ctx = make_ctx();
    local build = CATEGORY_SCREENS[name];
    if (build ~= nil) then
        n:push(build(ctx));
        return;
    end
    n:push(screens.placeholder(name, 'Unknown category.'));
end

local function open_group(group_def, n)
    n:push(screens.group(group_def, open_category));
end

local function ensure_root()
    if (nav:depth() == 0) then
        nav:reset(screens.home(open_group));
    end
end

local function set_open(value)
    state.open[1] = value and true or false;
    if (state.open[1]) then
        ensure_root();
        input.capture(true);
        state.focus_once = true;
        data.request_roster(make_ctx());
    else
        input.capture(false);
        cmd_queue:clear();
        nav:reset(nil);
        state.focus_once = false;
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

local function clear_search_focus()
    state.search_focus = false;
    if (imgui.SetKeyboardFocusHere ~= nil) then
        imgui.SetKeyboardFocusHere(-1);
    end
end

local function sync_screen_focus()
    local cur = nav:current();
    local sid = (cur ~= nil and cur.id) or nil;
    if (sid ~= state.last_screen_id) then
        state.last_screen_id = sid;
        clear_search_focus();
        if (imgui.SetKeyboardFocusHere ~= nil) then
            imgui.SetKeyboardFocusHere(-1);
        end
    end
end

local function sync_list_state()
    sync_screen_focus();
    local cur = nav:current();
    if (cur == nil) then
        return;
    end
    local sig = (cur.id or '') .. '|' .. tostring(nav:row_count());
    if (cur.search ~= nil) then
        sig = sig .. '|' .. tostring(cur.search[1] or '');
    end
    if (sig ~= state.last_list_sig) then
        state.last_list_sig = sig;
        nav:set_list_page(1);
        nav:ensure_focus_visible();
    end
end

local function handle_input()
    sync_list_state();
    local cur = nav:current();
    local has_search = (cur ~= nil and cur.search ~= nil);

    -- Filter field active: B returns to list; do not move rows.
    -- Only block list navigation when this screen owns the search field.
    if (has_search and imgui.IsAnyItemActive ~= nil and imgui.IsAnyItemActive()) then
        if (key_pressed(ImGuiKey_Escape) or key_pressed(ImGuiKey_GamepadFaceRight) or pad.pressed(pad.BTN.B)) then
            clear_search_focus();
            return;
        end
        return;
    end

    -- Filter highlighted but not typing yet.
    if (state.search_focus) then
        if (key_pressed(ImGuiKey_DownArrow) or key_pressed(ImGuiKey_GamepadDpadDown) or pad.pressed(pad.BTN.DOWN)) then
            clear_search_focus();
            nav.focus = 1;
            nav:ensure_focus_visible();
            return;
        end
        if (key_pressed(ImGuiKey_Enter) or key_pressed(ImGuiKey_GamepadFaceDown) or pad.pressed(pad.BTN.A)) then
            state.search_focus = true;
            return;
        end
        if (key_pressed(ImGuiKey_Escape) or key_pressed(ImGuiKey_GamepadFaceRight) or pad.pressed(pad.BTN.B)) then
            clear_search_focus();
            return;
        end
        return;
    end

    if (key_pressed(ImGuiKey_LeftArrow) or key_pressed(ImGuiKey_GamepadDpadLeft) or pad.pressed(pad.BTN.LEFT)) then
        nav:move_page(-1);
    end
    if (key_pressed(ImGuiKey_RightArrow) or key_pressed(ImGuiKey_GamepadDpadRight) or pad.pressed(pad.BTN.RIGHT)) then
        nav:move_page(1);
    end
    if (key_pressed(ImGuiKey_UpArrow) or key_pressed(ImGuiKey_GamepadDpadUp) or pad.pressed(pad.BTN.UP)) then
        if (has_search and nav.focus == 1 and nav:list_page() == 1) then
            state.search_focus = true;
            return;
        end
        nav:move(-1);
    end
    if (key_pressed(ImGuiKey_DownArrow) or key_pressed(ImGuiKey_GamepadDpadDown) or pad.pressed(pad.BTN.DOWN)) then
        nav:move(1);
    end
    if (key_pressed(ImGuiKey_Enter) or key_pressed(ImGuiKey_GamepadFaceDown) or pad.pressed(pad.BTN.A)) then
        nav:confirm();
    end
    if (key_pressed(ImGuiKey_Escape) or key_pressed(ImGuiKey_GamepadFaceRight) or pad.pressed(pad.BTN.B)) then
        local result = nav:back();
        if (result == 'close') then
            set_open(false);
        end
    end
end

local DESC_LINES = 2;

local function vec_x(v, fallback)
    if (v == nil) then
        return fallback or 0;
    end
    if (type(v) == 'number') then
        return v;
    end
    return v.x or v[1] or fallback or 0;
end

local function vec_y(v, fallback)
    if (v == nil) then
        return fallback or 0;
    end
    if (type(v) == 'number') then
        return v;
    end
    return v.y or v[2] or fallback or 0;
end

local function text_line_height()
    if (imgui.GetTextLineHeightWithSpacing ~= nil) then
        return imgui.GetTextLineHeightWithSpacing();
    end
    return scale_mod.list_line_height(theme.scale());
end

local function window_content_height()
    if (imgui.GetWindowContentRegionMax ~= nil and imgui.GetWindowContentRegionMin ~= nil) then
        local cmax = imgui.GetWindowContentRegionMax();
        local cmin = imgui.GetWindowContentRegionMin();
        local h = vec_y(cmax, 0) - vec_y(cmin, 0);
        if (h > 0) then
            return h;
        end
    end
    if (imgui.GetContentRegionAvail ~= nil) then
        local y = vec_y(imgui.GetContentRegionAvail(), 0);
        if (y > 0) then
            return y;
        end
    end
    local ws = theme.window_size();
    local pad = scale_mod.padding(theme.scale());
    return math.max(0, (ws[2] or scale_mod.WINDOW_H) - (pad[2] or 10) * 2);
end

local function compute_list_layout(cur)
    local lh = text_line_height();
    local scale = theme.scale();
    local has_filter = (cur ~= nil and cur.search ~= nil);
    local has_status = (nav.status ~= nil and nav.status ~= '');
    local chrome_top = layout.chrome_above(lh, scale, {
        has_filter = has_filter,
        desc_lines = DESC_LINES,
        has_status = has_status,
    });
    local chrome_bottom = layout.footer_height(lh, {
        footer_lines = 1,
        page_indicator = true,
        separators = 1,
        extra_chrome = math.floor(4 * scale + 0.5),
    });
    local content_h = window_content_height();
    return layout.split_content_budget(content_h, lh, chrome_top, chrome_bottom);
end

local child_panel_open = false;

local function begin_panel(id, height, border)
    child_panel_open = false;
    border = (border == nil) and true or border;
    if (imgui.BeginChild == nil) then
        return false;
    end
    local flags = ImGuiWindowFlags_NoScrollbar;
    if (ImGuiWindowFlags_NoScrollWithMouse ~= nil) then
        flags = bit.bor(flags, ImGuiWindowFlags_NoScrollWithMouse);
    end
    local began = false;
    local visible = false;
    local ok = pcall(function()
        visible = imgui.BeginChild(id, { -1, height }, border, flags);
        began = true;
    end);
    if (not ok) then
        ok = pcall(function()
            visible = imgui.BeginChild(id, -1, height, border, flags);
            began = true;
        end);
    end
    if (began and visible) then
        child_panel_open = true;
        return true;
    end
    if (began and imgui.EndChild ~= nil) then
        imgui.EndChild();
    end
    return false;
end

local function end_panel()
    if (child_panel_open and imgui.EndChild ~= nil) then
        imgui.EndChild();
        child_panel_open = false;
    end
end

local function draw_filter(cur, filter_h)
    if (cur == nil or cur.search == nil) then
        return;
    end
    if (begin_panel('##dwhub_filter', filter_h, false)) then
    local filter_active = (imgui.IsAnyItemActive ~= nil and imgui.IsAnyItemActive());
    local filter_focused = state.search_focus or filter_active;
    local default_label = (cur.search_required and (cur.search_label or 'Text'))
        or 'Filter (optional — Up from top row)';
    local filter_label = filter_focused and ('> ' .. default_label) or default_label;
    imgui.TextColored(filter_focused and theme.colors.selection or theme.colors.textDim, filter_label);
    if (state.search_focus and not filter_active and imgui.SetKeyboardFocusHere ~= nil) then
        imgui.SetKeyboardFocusHere();
    end
    imgui.PushItemWidth(-1);
    imgui.InputText('##dwhub_search', cur.search, 64);
    imgui.PopItemWidth();
    if (filter_focused) then
        imgui.TextColored(theme.colors.textDim, 'Down: list   B: back to list');
    end
    end_panel();
    end
end

local function draw_description(desc_h)
    local title = 'Category Selection';
    local cur = nav:current();
    if (cur ~= nil and cur.title ~= nil) then
        title = cur.title;
    end
    if (begin_panel('##dwhub_desc', desc_h, false)) then
        imgui.TextColored(theme.colors.title, title);
        imgui.TextWrapped(nav:description());
        if (nav.status ~= nil and nav.status ~= '') then
            imgui.TextColored(theme.colors.textDim, nav.status);
        end
        end_panel();
    end
end

local function draw_list_rows(start_i, stop_i, rows)
    if (stop_i < start_i) then
        imgui.TextColored(theme.colors.textDim, '  (empty)');
        return;
    end
    for i = start_i, stop_i do
        local row = rows[i];
        if (row ~= nil) then
            local focused = (i == nav.focus);
            local label = row.label or '?';
            if (focused) then
                label = '> ' .. label;
                local col = row.dim and theme.colors.textDim or theme.colors.selection;
                imgui.TextColored(col, label);
            else
                local col = row.dim and theme.colors.textDim or theme.colors.text;
                imgui.TextColored(col, '  ' .. label);
            end
        end
    end
end

local function draw_list(list_h)
    local cur = nav:current();
    if (cur == nil) then
        return false;
    end
    local rows = cur:rows();
    local start_i, stop_i = nav:page_row_range();
    if (begin_panel('##dwhub_list', list_h, true)) then
        draw_list_rows(start_i, stop_i, rows);
        end_panel();
    else
        local pos_x, pos_y = 0, 0;
        if (imgui.GetCursorScreenPos ~= nil) then
            pos_x, pos_y = imgui.GetCursorScreenPos();
        end
        local w = theme.window_size()[1] or scale_mod.WINDOW_W;
        if (imgui.GetContentRegionAvail ~= nil) then
            w = vec_x(imgui.GetContentRegionAvail(), w);
        end
        if (imgui.PushClipRect ~= nil) then
            imgui.PushClipRect(
                { pos_x, pos_y },
                { pos_x + w, pos_y + list_h },
                true
            );
        end
        draw_list_rows(start_i, stop_i, rows);
        if (imgui.PopClipRect ~= nil) then
            imgui.PopClipRect();
        end
        if (imgui.Dummy ~= nil) then
            imgui.Dummy({ -1, list_h });
        end
    end
    return nav:page_count() > 1;
end

local function draw_window()
    if (state.focus_once) then
        imgui.SetNextWindowSize(theme.window_size(), ImGuiCond_Always);
        imgui.SetNextWindowPos(theme.window_pos(), ImGuiCond_Always);
        imgui.SetNextWindowFocus();
        state.focus_once = false;
    end

    local window_flags = bit.bor(ImGuiWindowFlags_NoCollapse, ImGuiWindowFlags_NoScrollbar);
    if (ImGuiWindowFlags_NoScrollWithMouse ~= nil) then
        window_flags = bit.bor(window_flags, ImGuiWindowFlags_NoScrollWithMouse);
    end
    local visible = imgui.Begin('DriftwoodXI Pad Hub##dwhub', state.open, window_flags);
    if (visible) then
        local font_pushed = theme.push_font();
        local cur = nav:current();
        local lh = text_line_height();
        local scale = theme.scale();
        local has_filter = (cur ~= nil and cur.search ~= nil);
        local has_status = (nav.status ~= nil and nav.status ~= '');

        local list_h, page_size = compute_list_layout(cur);
        nav:set_page_size(page_size);
        nav:ensure_focus_visible();

        handle_input();

        local filter_h = layout.filter_height(lh, scale);
        local desc_h = layout.desc_height(lh, scale, {
            desc_lines = DESC_LINES,
            has_status = has_status,
        });

        draw_filter(cur, filter_h);
        if (has_filter) then
            imgui.Separator();
        end
        draw_description(desc_h);
        imgui.Separator();

        local rows = (cur ~= nil and cur.rows ~= nil) and cur:rows() or {};
        local show_page = draw_list(list_h);

        if (show_page) then
            imgui.TextColored(theme.colors.textDim, string.format(
                'Page %d / %d  (%d items)   ← →',
                nav:list_page(),
                nav:page_count(),
                #rows
            ));
        end
        imgui.Separator();
        local footer_hint = (cur ~= nil and cur.search_required) and '← → pages   Up: text   A Confirm   B Back'
            or '← → pages   Up: filter   A Confirm   B Back';
        local footer = (nav:depth() <= 1) and (footer_hint:gsub('Back', 'Close')) or footer_hint;
        imgui.TextColored(theme.colors.textDim, footer);
        if (cmd_queue:len() > 0) then
            imgui.SameLine();
            imgui.TextColored(theme.colors.textDim, string.format('  queue:%d', cmd_queue:len()));
        end
        theme.pop_font(font_pushed);
    end
    imgui.End();

    if (not state.open[1]) then
        nav:reset(nil);
        input.capture(false);
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
    if (state.open[1]) then
        data.tick(make_ctx());
    end

    if (not state.open[1]) then
        return;
    end

    ensure_root();

    theme.update();
    local token = theme.push();
    local ok, err = pcall(draw_window);
    theme.pop(token);
    if (not ok) then
        print(chat.header('dwhub'):append(chat.error(tostring(err))));
    end
end);

ashita.events.register('load', 'dwhub_load', function ()
    input.capture(false);
    data.attach();
    print(chat.header('dwhub'):append(chat.message('/dwhub (or /hub) toggles the pad hub. D-pad / arrows move, A/Enter confirm, B/Esc back.')));
end);

ashita.events.register('unload', 'dwhub_unload', function ()
    input.capture(false);
    data.detach();
end);

return {
    state = state,
    set_open = set_open,
    toggle = toggle,
    nav = nav,
    queue = cmd_queue,
};
