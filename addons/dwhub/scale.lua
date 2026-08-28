--[[
* Display scaling for pad hub chrome.
*
* Design target: 1280×720 (Steam Deck). Window size, padding, and font scale
* grow/shrink with imgui.GetIO().DisplaySize.
--]]

local M = {};

M.BASE_W = 1280;
M.BASE_H = 720;

-- Default hub window at BASE resolution.
M.WINDOW_W = 520;
M.WINDOW_H = 400;
M.WINDOW_X = 40;
M.WINDOW_Y = 60;

M.MIN_SCALE = 0.85;
M.MAX_SCALE = 3.0;

--- Scale factor from display pixels (pure; unit-tested).
function M.from_display(w, h)
    w = tonumber(w) or M.BASE_W;
    h = tonumber(h) or M.BASE_H;
    if (w <= 0 or h <= 0) then
        return 1.0;
    end
    local sw = w / M.BASE_W;
    local sh = h / M.BASE_H;
    local s = math.min(sw, sh);
    if (s < M.MIN_SCALE) then
        return M.MIN_SCALE;
    end
    if (s > M.MAX_SCALE) then
        return M.MAX_SCALE;
    end
    return s;
end

function M.window_size(scale)
    scale = scale or 1.0;
    return {
        math.floor(M.WINDOW_W * scale + 0.5),
        math.floor(M.WINDOW_H * scale + 0.5),
    };
end

function M.window_pos(scale)
    scale = scale or 1.0;
    return {
        math.floor(M.WINDOW_X * scale + 0.5),
        math.floor(M.WINDOW_Y * scale + 0.5),
    };
end

function M.padding(scale)
    scale = scale or 1.0;
    local p = math.floor(10 * scale + 0.5);
    return { p, p };
end

function M.item_spacing(scale)
    scale = scale or 1.0;
    return {
        math.floor(4 * scale + 0.5),
        math.floor(4 * scale + 0.5),
    };
end

function M.list_page_size(scale)
    scale = scale or 1.0;
    -- Upper cap only; actual page size comes from layout.split_list_budget().
    return math.max(4, math.floor(8 * scale + 0.5));
end

function M.list_line_height(scale)
    scale = scale or 1.0;
    return math.floor(18 * scale + 0.5);
end

return M;
