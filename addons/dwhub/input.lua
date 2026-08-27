--[[
* DriftwoodXI Pad Hub — input guard
*
* While the hub is open we keep FFXI from also eating navigation:
*   - SetDisableGamepad on the input manager (pad)
*   - IKeyboard:SetBlockInput (arrows / Enter / Esc / typing)
*
* Ashita still delivers those keys to ImGui, so hub nav and top search fields
* keep working. Closing restores the previous flags.
*
* Best-effort: missing APIs are skipped; docs note the fallback.
--]]

local M = {
    _active = false,
    _prev_disable_gamepad = nil,
    _prev_block_keyboard = nil,
};

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

    local im = input_manager();
    local kb = keyboard();

    if (enable) then
        if (im ~= nil) then
            local ok, prev = pcall(function()
                return im:GetDisableGamepad();
            end);
            if (ok) then
                M._prev_disable_gamepad = prev;
            end
            pcall(function()
                im:SetDisableGamepad(true);
            end);
        end

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

        -- Prefer ImGui keyboard/gamepad nav while the hub owns focus.
        pcall(function()
            local io = imgui.GetIO();
            if (io ~= nil and io.ConfigFlags ~= nil) then
                io.ConfigFlags = bit.bor(io.ConfigFlags, ImGuiConfigFlags_NavEnableGamepad);
                io.ConfigFlags = bit.bor(io.ConfigFlags, ImGuiConfigFlags_NavEnableKeyboard);
            end
        end);

        M._active = true;
    else
        if (im ~= nil) then
            local prev = M._prev_disable_gamepad;
            pcall(function()
                if (prev ~= nil) then
                    im:SetDisableGamepad(prev);
                else
                    im:SetDisableGamepad(false);
                end
            end);
            M._prev_disable_gamepad = nil;
        end

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

        M._active = false;
    end
end

return M;
