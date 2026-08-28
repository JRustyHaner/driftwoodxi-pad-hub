--[[
* List viewport sizing — pure helpers (unit-tested).
*
* The hub window has a fixed size; list rows must fit in whatever vertical
* space remains after the filter field, description, and footer.
--]]

local M = {};

--- How many list rows fit in a pixel height?
function M.page_size_for_height(list_h, line_h)
    list_h = tonumber(list_h) or 0;
    line_h = tonumber(line_h) or 18;
    if (line_h <= 0) then
        line_h = 18;
    end
    if (list_h <= 0) then
        return 1;
    end
    return math.max(1, math.floor(list_h / line_h));
end

function M.list_height_for_rows(page_size, line_h)
    page_size = math.max(1, tonumber(page_size) or 1);
    line_h = tonumber(line_h) or 18;
    if (line_h <= 0) then
        line_h = 18;
    end
    return page_size * line_h;
end

--- Split remaining window height between the list child and chrome below it.
function M.split_list_budget(avail_y, line_h, opts)
    opts = opts or {};
    local footer_lines = opts.footer_lines or 1;
    local page_indicator = opts.page_indicator and true or false;
    if (page_indicator) then
        footer_lines = footer_lines + 1;
    end
    line_h = tonumber(line_h) or 18;
    if (line_h <= 0) then
        line_h = 18;
    end
    local chrome_h = footer_lines * line_h + (opts.extra_chrome or 0);
    local list_h = (tonumber(avail_y) or 0) - chrome_h;
    if (list_h < line_h) then
        list_h = line_h;
    end
    local page_size = M.page_size_for_height(list_h, line_h);
    list_h = M.list_height_for_rows(page_size, line_h);
    return list_h, page_size;
end

return M;
