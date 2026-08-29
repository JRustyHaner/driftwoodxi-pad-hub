--[[
* DriftwoodXI Pad Hub — input guard
*
* While the hub is open we keep FFXI from also eating keyboard navigation:
*   - IKeyboard:SetBlockInput (arrows / Enter / Esc / typing)
*
* Gamepad is handled in pad.lua via xinput_state / xinput_button. Do NOT call
* SetDisableGamepad here — on Steam Deck it stops XInput events and breaks hub nav.
*
* Ashita still delivers blocked keys to ImGui when supported. Closing restores flags.
--]]

local M = {
    _active = false,
    _prev_block_keyboard = nil,
    _prev_io_flags = nil,
};

local pad = require('pad');

local function input_manager()
    if (AshitaCore == nil) then
        return nil;
    end
    local ok, im = pcall(function()
        return AshitaCore:GetInputManager();
    end);
    if (ok) then
        return im;
    end
    return nil;
end

local function keyboard()
    local im = input_manager();
    if (im == nil) then
        return nil;
    end
    local ok, kb = pcall(function()
        return im:GetKeyboard();
    end);
    if (ok) then
        return kb;
    end
    return nil;
end

function M.is_active()
    return M._active;
end

function M.capture(enable)
    enable = enable and true or false;
    if (enable == M._active) then
        return;
    end

    local kb = keyboard();

    if (enable) then
        if (kb ~= nil) then
            local ok, prev = pcall(function()
                return kb:GetBlockInput();
            end);
            if (ok) then
                M._prev_block_keyboard = prev;
            end
            pcall(function()
                kb:SetBlockInput(true);
            end);
        end

        pcall(function()
            local io = imgui.GetIO();
            if (io ~= nil and io.ConfigFlags ~= nil) then
                M._prev_io_flags = io.ConfigFlags;
                io.ConfigFlags = bit.bor(io.ConfigFlags, ImGuiConfigFlags_NavEnableGamepad);
                io.ConfigFlags = bit.bor(io.ConfigFlags, ImGuiConfigFlags_NavEnableKeyboard);
            end
        end);

        M._active = true;
        pad.set_active(true);
    else
        if (kb ~= nil) then
            local prev = M._prev_block_keyboard;
            pcall(function()
                if (prev ~= nil) then
                    kb:SetBlockInput(prev);
                else
                    kb:SetBlockInput(false);
                end
            end);
            M._prev_block_keyboard = nil;
        end

        pcall(function()
            local io = imgui.GetIO();
            if (io ~= nil and io.ConfigFlags ~= nil and M._prev_io_flags ~= nil) then
                io.ConfigFlags = M._prev_io_flags;
            end
        end);
        M._prev_io_flags = nil;

        M._active = false;
        pad.set_active(false);
    end
end

return M;
