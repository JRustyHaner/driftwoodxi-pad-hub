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

--- ImGui separator + spacing slack (pixels).
function M.separator_height(line_h)
    line_h = tonumber(line_h) or 18;
    return math.max(6, math.floor(line_h * 0.4 + 0.5));
end

--- Filter block: label + InputText + hint line.
function M.filter_height(line_h, scale)
    line_h = tonumber(line_h) or 18;
    scale = tonumber(scale) or 1.0;
    return line_h * 3 + math.floor(4 * scale + 0.5);
end

--- Description block: title + wrapped body (+ optional status line).
function M.desc_height(line_h, scale, opts)
    opts = opts or {};
    line_h = tonumber(line_h) or 18;
    scale = tonumber(scale) or 1.0;
    local lines = tonumber(opts.desc_lines) or 2;
    if (opts.has_status) then
        lines = lines + 1;
    end
    return line_h * lines + math.floor(4 * scale + 0.5);
end

--- Footer block below the list: optional page line, separator, hint line.
function M.footer_height(line_h, opts)
    opts = opts or {};
    line_h = tonumber(line_h) or 18;
    local text_lines = opts.footer_lines or 1;
    if (opts.page_indicator) then
        text_lines = text_lines + 1;
    end
    local sep_count = opts.separators or 1;
    local sep_h = sep_count * M.separator_height(line_h);
    return text_lines * line_h + sep_h + (opts.extra_chrome or 0);
end

--- Chrome above the list (filter + separators + description + separator).
function M.chrome_above(line_h, scale, opts)
    opts = opts or {};
    line_h = tonumber(line_h) or 18;
    scale = tonumber(scale) or 1.0;
    local h = 0;
    if (opts.has_filter) then
        h = h + M.filter_height(line_h, scale) + M.separator_height(line_h);
    end
    h = h + M.desc_height(line_h, scale, {
        desc_lines = opts.desc_lines,
        has_status = opts.has_status,
    });
    h = h + M.separator_height(line_h);
    return h;
end

--- Given full window content height, return list viewport height and row count.
function M.split_content_budget(content_h, line_h, chrome_above, chrome_below)
    content_h = tonumber(content_h) or 0;
    line_h = tonumber(line_h) or 18;
    chrome_above = tonumber(chrome_above) or 0;
    chrome_below = tonumber(chrome_below) or 0;

    local list_h = content_h - chrome_above - chrome_below;
    if (list_h < line_h) then
        list_h = line_h;
    end
    local page_size = M.page_size_for_height(list_h, line_h);
    list_h = M.list_height_for_rows(page_size, line_h);
    return list_h, page_size;
end

--- Split remaining window height between the list child and chrome below it.
-- Deprecated path: prefer split_content_budget with explicit chrome heights.
function M.split_list_budget(avail_y, line_h, opts)
    opts = opts or {};
    local chrome_below = M.footer_height(line_h, opts);
    return M.split_content_budget(avail_y, line_h, 0, chrome_below);
end

return M;
