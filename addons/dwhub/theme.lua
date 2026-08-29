--[[
* DriftwoodXI Pad Hub — theme
*
* FFXI-style chrome tokens from docs/mockups/ffxi-hub-chrome.html:
* navy glass windows, etched borders, yellow selection, white focus text.
*
* push() / pop() wrap Begin/End so the style stack stays balanced.
* Font and spacing scale with game display size (1280×720 baseline).
--]]

local imgui = require('imgui');
local scale_mod = require('scale');

local M = {};

-- 0..1 RGBA
local function rgba(r, g, b, a)
    return { r / 255, g / 255, b / 255, a or 1.0 };
end

M.colors = {
    windowBg     = rgba(0, 0, 51, 0.85),
    windowBgTop  = rgba(0, 0, 102, 0.85),
    border       = rgba(204, 204, 204, 1.0),
    borderInner  = rgba(102, 102, 102, 1.0),
    text         = rgba(255, 255, 255, 1.0),
    textDim      = rgba(170, 170, 170, 1.0),
    selection    = rgba(255, 255, 0, 1.0),
    title        = rgba(255, 255, 0, 1.0),
    frameBg      = rgba(0, 0, 80, 0.9),
    button       = rgba(0, 0, 102, 0.9),
    buttonHover  = rgba(40, 40, 140, 0.95),
    buttonActive = rgba(60, 60, 160, 1.0),
};

local current_scale = 1.0;

local function display_size()
    local ok, io = pcall(function()
        return imgui.GetIO();
    end);
    if (not ok or io == nil or io.DisplaySize == nil) then
        return scale_mod.BASE_W, scale_mod.BASE_H;
    end
    local ds = io.DisplaySize;
    local w = scale_mod.BASE_W;
    local h = scale_mod.BASE_H;
    local dst = type(ds);
    -- Ashita sugar extends numbers with __index -> math; never use .x/.y on a bare number.
    if (dst == 'table' or dst == 'userdata') then
        w = ds[1] or ds.x or w;
        h = ds[2] or ds.y or h;
    end
    return w, h;
end

--- Refresh scale from the current game framebuffer (call each frame while open).
function M.update()
    local w, h = display_size();
    current_scale = scale_mod.from_display(w, h);
end

function M.scale()
    return current_scale;
end

function M.window_size()
    return scale_mod.window_size(current_scale);
end

function M.window_pos()
    return scale_mod.window_pos(current_scale);
end

--- Push ImGui style for an FFXI-ish window. Returns count of colors + vars pushed.
function M.push()
    local c = M.colors;
    local nCol = 0;
    local nVar = 0;
    local s = current_scale;

    imgui.PushStyleColor(ImGuiCol_WindowBg, c.windowBg); nCol = nCol + 1;
    imgui.PushStyleColor(ImGuiCol_Border, c.border); nCol = nCol + 1;
    imgui.PushStyleColor(ImGuiCol_Text, c.text); nCol = nCol + 1;
    imgui.PushStyleColor(ImGuiCol_TitleBg, c.windowBgTop); nCol = nCol + 1;
    imgui.PushStyleColor(ImGuiCol_TitleBgActive, c.windowBgTop); nCol = nCol + 1;
    imgui.PushStyleColor(ImGuiCol_FrameBg, c.frameBg); nCol = nCol + 1;
    imgui.PushStyleColor(ImGuiCol_Button, c.button); nCol = nCol + 1;
    imgui.PushStyleColor(ImGuiCol_ButtonHovered, c.buttonHover); nCol = nCol + 1;
    imgui.PushStyleColor(ImGuiCol_ButtonActive, c.buttonActive); nCol = nCol + 1;
    imgui.PushStyleColor(ImGuiCol_Header, c.button); nCol = nCol + 1;
    imgui.PushStyleColor(ImGuiCol_HeaderHovered, c.buttonHover); nCol = nCol + 1;
    imgui.PushStyleColor(ImGuiCol_HeaderActive, c.buttonActive); nCol = nCol + 1;
    imgui.PushStyleColor(ImGuiCol_ScrollbarBg, c.windowBg); nCol = nCol + 1;
    imgui.PushStyleColor(ImGuiCol_ScrollbarGrab, c.borderInner); nCol = nCol + 1;

    imgui.PushStyleVar(ImGuiStyleVar_WindowRounding, 0); nVar = nVar + 1;
    imgui.PushStyleVar(ImGuiStyleVar_FrameRounding, 0); nVar = nVar + 1;
    imgui.PushStyleVar(ImGuiStyleVar_WindowBorderSize, 1); nVar = nVar + 1;
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, scale_mod.padding(s)); nVar = nVar + 1;
    imgui.PushStyleVar(ImGuiStyleVar_ItemSpacing, scale_mod.item_spacing(s)); nVar = nVar + 1;

    return { colors = nCol, vars = nVar };
end

function M.pop(token)
    if (token == nil) then
        return;
    end
    if (token.vars and token.vars > 0) then
        imgui.PopStyleVar(token.vars);
    end
    if (token.colors and token.colors > 0) then
        imgui.PopStyleColor(token.colors);
    end
end

--- Scale text inside an open window. Returns true when PushFont was used.
function M.push_font()
    local s = current_scale;
    if (s == 1.0) then
        return false;
    end
    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(s);
        return false;
    end
    if (imgui.PushFont ~= nil and imgui.GetFont ~= nil and imgui.GetFontSize ~= nil) then
        imgui.PushFont(imgui.GetFont(), imgui.GetFontSize() * s);
        return true;
    end
    return false;
end

function M.pop_font(pushed)
    if (pushed) then
        imgui.PopFont();
    elseif (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(1.0);
    end
end

return M;
