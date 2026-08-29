--[[
* Load committed parse fixtures from spec/fixtures/*.lines
*
* File format:
*   # sender: _DWSDATA     (machine fixtures)
*   # verb: who              (documentation only)
*   # kind: port | spell     (chat scraper fixtures)
*   # tag: whm               (spell fixtures)
*   payload lines...
]]

local M = {};

local FIXTURE_DIR = 'spec/fixtures/';

local function trim(s)
    return (s or ''):gsub('^%s+', ''):gsub('%s+$', '');
end

local function parse_meta(line)
    local key, value = line:match('^#%s*([%w_]+)%s*:%s*(.+)$');
    if (key == nil) then
        return nil, nil;
    end
    return string.lower(key), trim(value);
end

--- Read one fixture file; returns { meta = {}, lines = {} }.
function M.load(name)
    local path = FIXTURE_DIR .. name .. '.lines';
    local f, err = io.open(path, 'r');
    if (f == nil) then
        error(string.format('fixture %s: %s', name, err or 'open failed'));
    end

    local meta = {};
    local lines = {};
    for raw in f:lines() do
        local line = trim(raw);
        if (line == '') then
            -- skip blanks
        elseif (line:sub(1, 1) == '#') then
            local key, value = parse_meta(line);
            if (key ~= nil) then
                meta[key] = value;
            end
        else
            lines[#lines + 1] = line;
        end
    end
    f:close();

    return { meta = meta, lines = lines, name = name };
end

--- Apply a machine-channel fixture via data.handle_machine.
function M.apply_machine(data, fixture)
    local sender = fixture.meta.sender;
    if (sender == nil or sender == '') then
        error(string.format('fixture %s: missing # sender:', fixture.name));
    end
    for _, line in ipairs(fixture.lines) do
        data.handle_machine(sender, line);
    end
end

--- Apply port-list chat lines (calls begin_port_list unless tab given).
function M.apply_port(data, fixture, tab)
    data.begin_port_list(tab or 'hp');
    for _, line in ipairs(fixture.lines) do
        data.handle_port_line(line);
    end
end

--- Apply spell-list chat lines.
function M.apply_spell(data, fixture)
    local tag = fixture.meta.tag or 'whm';
    data.begin_spell_list(tag);
    for _, line in ipairs(fixture.lines) do
        data.handle_spell_line(line);
    end
end

return M;
