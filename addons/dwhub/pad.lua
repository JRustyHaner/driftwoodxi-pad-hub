--[[
* Xbox / XInput pad input for dwhub.
*
* Ashita exposes controller state via xinput_state / xinput_button. ImGui
* Gamepad* keys are not reliably fed on desktop or Deck. While the hub is open
* we read buttons here and zero state_modified so FFXI does not also act on them.
*
* Do NOT use SetDisableGamepad alongside this — it prevents xinput events on Deck.
--]]

local M = {};

M.BTN = {
    UP    = 0x0001,
    DOWN  = 0x0002,
    LEFT  = 0x0004,
    RIGHT = 0x0008,
    START = 0x0010,
    BACK  = 0x0020,
    A     = 0x1000,
    B     = 0x2000,
    X     = 0x4000,
    Y     = 0x8000,
};

-- Ashita xinput_button ids (see cBind controllers/xinput.lua).
local XINPUT_BTN = {
    [0]  = M.BTN.UP,
    [1]  = M.BTN.DOWN,
    [2]  = M.BTN.LEFT,
    [3]  = M.BTN.RIGHT,
    [12] = M.BTN.A,
    [13] = M.BTN.B,
};

local active = false;
local curr_buttons = 0;
local prev_buttons = 0;
local pending = {};

local function gamepad_table(state)
    if (state == nil) then
        return nil;
    end
    -- Ashita builds vary: nested Gamepad/gamepad or flat wButtons on state.
    if (state.wButtons ~= nil or state.WButtons ~= nil) then
        return state;
    end
    return state.Gamepad or state.gamepad;
end

--- Accept event table or (size, user, state, state_modified) args.
local function normalize_xinput_event(a1, a2, a3, a4)
    if (a1 == nil) then
        return nil;
    end
    if (type(a1) == 'table' and (a1.state ~= nil or a1.state_modified ~= nil or a1.State ~= nil)) then
        return a1;
    end
    if (type(a1) == 'number') then
        return { size = a1, user = a2, state = a3, state_modified = a4 };
    end
    if (type(a1) == 'table' or type(a1) == 'userdata') then
        return { state = a1, state_modified = a2 };
    end
    return nil;
end

local function read_buttons(state)
    local gp = gamepad_table(state);
    if (gp == nil) then
        return 0;
    end
    return gp.wButtons or gp.WButtons or 0;
end

local function clear_modified(state_modified)
    local gp = gamepad_table(state_modified);
    if (gp == nil) then
        return;
    end
    gp.wButtons = 0;
    if (gp.bLeftTrigger ~= nil) then gp.bLeftTrigger = 0; end
    if (gp.bRightTrigger ~= nil) then gp.bRightTrigger = 0; end
    if (gp.sThumbLX ~= nil) then gp.sThumbLX = 0; end
    if (gp.sThumbLY ~= nil) then gp.sThumbLY = 0; end
    if (gp.sThumbRX ~= nil) then gp.sThumbRX = 0; end
    if (gp.sThumbRY ~= nil) then gp.sThumbRY = 0; end
end

--- Edge-detect a button mask (pure; unit-tested).
function M.edge_pressed(curr, prev, mask)
    return bit.band(curr, mask) ~= 0 and bit.band(prev, mask) == 0;
end

function M.set_active(enable)
    active = enable and true or false;
    if (not active) then
        curr_buttons = 0;
        prev_buttons = 0;
        pending = {};
    end
end

function M.is_active()
    return active;
end

--- xinput_button fallback (Deck / some Ashita builds).
function M.on_xinput_button(e)
    if (not active or e == nil or e.button == nil) then
        return;
    end
    if (e.state ~= 1) then
        return;
    end
    local mask = XINPUT_BTN[e.button];
    if (mask ~= nil) then
        pending[mask] = true;
        e.blocked = true;
    end
end

--- Called from xinput_state each frame (event table or size/user/state/modified args).
function M.on_xinput_state(a1, a2, a3, a4)
    if (not active) then
        return;
    end

    local e = normalize_xinput_event(a1, a2, a3, a4);
    if (e == nil) then
        return;
    end
    local state = e.state or e.State;
    local modified = e.state_modified or e.StateModified;
    prev_buttons = curr_buttons;
    local buttons = read_buttons(state);
    if (buttons == 0) then
        buttons = read_buttons(modified);
    end
    curr_buttons = buttons;
    clear_modified(modified);
end

function M.pressed(mask)
    if (pending[mask]) then
        pending[mask] = nil;
        return true;
    end
    return M.edge_pressed(curr_buttons, prev_buttons, mask);
end

if (ashita ~= nil and ashita.events ~= nil) then
    ashita.events.register('xinput_state', 'dwhub_xinput_state', function(...)
        M.on_xinput_state(...);
    end);
    ashita.events.register('xinput_button', 'dwhub_xinput_button', function(e)
        M.on_xinput_button(e);
    end);
end

return M;
