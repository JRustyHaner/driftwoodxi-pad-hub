--[[
* DriftwoodXI Pad Hub — input guard
*
* While the hub is open we try to keep FFXI from also eating A/B/D-pad.
* Ashita exposes SetDisableGamepad on the input manager; we flip it for the
* duration and restore the previous value on close.
*
* Hub navigation still works via keyboard mirrors (arrows / Enter / Esc) and
* ImGui gamepad nav flags when the backend feeds them. Steam Deck macros that
* emit those keys remain the most reliable path.
*
* Best-effort: if the API is missing, capture() is a no-op and docs say so.
--]]

local M = {
    _active = false,
    _prev_disable = nil,
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

function M.is_active()
    return M._active;
end

function M.capture(enable)
    enable = enable and true or false;
    if (enable == M._active) then
        return;
    end

    local im = input_manager();
    if (im == nil) then
        M._active = enable;
        return;
    end

    if (enable) then
        local ok, prev = pcall(function()
            return im:GetDisableGamepad();
        end);
        if (ok) then
            M._prev_disable = prev;
        end
        pcall(function()
            im:SetDisableGamepad(true);
        end);
        -- Enable ImGui gamepad nav if IO is available
        pcall(function()
            local io = imgui.GetIO();
            if (io ~= nil and io.ConfigFlags ~= nil) then
                io.ConfigFlags = bit.bor(io.ConfigFlags, ImGuiConfigFlags_NavEnableGamepad);
                io.ConfigFlags = bit.bor(io.ConfigFlags, ImGuiConfigFlags_NavEnableKeyboard);
            end
        end);
        M._active = true;
    else
        if (M._prev_disable ~= nil) then
            local prev = M._prev_disable;
            pcall(function()
                im:SetDisableGamepad(prev);
            end);
            M._prev_disable = nil;
        else
            pcall(function()
                im:SetDisableGamepad(false);
            end);
        end
        M._active = false;
    end
end

return M;
