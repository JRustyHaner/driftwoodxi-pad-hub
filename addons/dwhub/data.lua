--[[
* Live list data for pad picks.
*
* Observes Driftwood machine channels (_DWSDATA / _DWDATA / _DWJDATA / _DWGDATA)
* without blocking them — official dw* addons own those senders. Also scrapes
* human !port list lines while a port tab is expecting results.
*
* Pure parse helpers are unit-tested; Ashita packet wiring lives in attach().
--]]

local M = {};

local PROTOCOL = 1;
local CHAR_SELF = 4;

local SENDERS = {
    ['_DWSDATA'] = 'squad',
    ['_DWDATA']  = 'bags',
    ['_DWJDATA'] = 'jobs',
    ['_DWGDATA'] = 'rules',
};

local function split(text, sep)
    local parts = {};
    for piece in string.gmatch(text .. sep, '([^' .. sep .. ']*)' .. sep) do
        parts[#parts + 1] = piece;
    end
    return parts;
end

local function sorted_names(map)
    local names = {};
    for name, _ in pairs(map) do
        names[#names + 1] = name;
    end
    table.sort(names, function(a, b)
        return string.lower(a) < string.lower(b);
    end);
    return names;
end

local function new_state()
    return {
        chars = {},           -- array { charid, name, flags, slot, mjob, mlvl }
        finds = {},           -- array { charid, loc, itemid, qty, name }
        bags = {},            -- [loc] = { used, size, items = { entry... } }
        bag_charid = nil,     -- whose bags we last requested / are filling
        bag_charname = nil,
        job_presets = {},     -- array of names
        rule_sets = {},       -- map name -> true
        rule_presets = {},    -- map name -> true
        port_tab = nil,
        port_dests = {},      -- array { id, label, usable }
        port_expecting = false,
        status = '',
        inbound = {
            channel = nil,
            verb = nil,
            buffer = nil,
        },
    };
end

-- Container ids, matching dwbags / server item_container.h.
M.LOC_NAMES = {
    [0]  = 'Inventory', [1]  = 'Mog Safe',  [2]  = 'Storage',   [3]  = 'Temp',
    [4]  = 'Locker',    [5]  = 'Satchel',   [6]  = 'Sack',      [7]  = 'Case',
    [8]  = 'Wardrobe',  [9]  = 'Mog Safe 2',[10] = 'Wardrobe 2',[11] = 'Wardrobe 3',
    [12] = 'Wardrobe 4',[13] = 'Wardrobe 5',[14] = 'Wardrobe 6',[15] = 'Wardrobe 7',
    [16] = 'Wardrobe 8',[17] = 'Recycle Bin',
};

local state = new_state();
local item_name_fn = nil;
local attached = false;

function M.reset()
    state = new_state();
end

function M.state()
    return state;
end

function M.set_item_name_fn(fn)
    item_name_fn = fn;
end

local function resolve_item_name(itemid)
    if (item_name_fn ~= nil) then
        local n = item_name_fn(itemid);
        if (n ~= nil and n ~= '') then
            return n;
        end
    end
    if (AshitaCore ~= nil) then
        local item = AshitaCore:GetResourceManager():GetItemById(itemid);
        if (item ~= nil and item.Name ~= nil and item.Name[1] ~= nil and item.Name[1]:len() > 0) then
            return item.Name[1];
        end
    end
    return string.format('item %d', itemid);
end

--- Packed bag/find payload: `<slot>:<itemid>:<qty>:<flags>,...`
local function parse_packed(charid, loc, packed, into)
    for _, entry in ipairs(split(packed or '', ',')) do
        local bits = split(entry, ':');
        if (#bits >= 4) then
            local itemid = tonumber(bits[2]) or 0;
            if (itemid > 0) then
                into[#into + 1] = {
                    charid = charid,
                    loc = loc,
                    slot = tonumber(bits[1]) or 0,
                    itemid = itemid,
                    qty = tonumber(bits[3]) or 0,
                    flags = tonumber(bits[4]) or 0,
                    name = resolve_item_name(itemid),
                };
            end
        end
    end
end

local function chars_array_from_map(map)
    local list = {};
    for _, c in pairs(map) do
        list[#list + 1] = c;
    end
    table.sort(list, function(a, b)
        return string.lower(a.name or '') < string.lower(b.name or '');
    end);
    return list;
end

local function handle_squad_or_bags_or_jobs(channel, line)
    local parts = split(line, '|');
    local kind = parts[1];
    local inbound = state.inbound;

    if (kind == 'd') then
        local version = tonumber(parts[2]) or 0;
        if (version ~= PROTOCOL) then
            state.status = string.format('Protocol %d (expected %d) on %s', version, PROTOCOL, channel);
            inbound.channel = nil;
            inbound.verb = nil;
            return;
        end
        inbound.channel = channel;
        inbound.verb = parts[3];
        if (inbound.verb == 'who') then
            state._char_map = {};
            if (channel == 'jobs') then
                state.job_presets = {};
            end
        elseif (inbound.verb == 'find' and channel == 'bags') then
            state.finds = {};
        elseif (inbound.verb == 'bag' and channel == 'bags') then
            state.bags = {};
        elseif (inbound.verb == 'list' and channel == 'jobs') then
            state.job_presets = {};
        end
        return;
    end

    if (kind == 'm' or kind == 'e') then
        state.status = line:sub(3);
        return;
    end

    if (inbound.channel ~= channel or inbound.verb == nil) then
        return;
    end

    if (kind == 'z') then
        if (inbound.verb == 'who' and state._char_map ~= nil) then
            state.chars = chars_array_from_map(state._char_map);
            state._char_map = nil;
        end
        inbound.channel = nil;
        inbound.verb = nil;
        return;
    end

    if (kind == 'c' and inbound.verb == 'who') then
        local charid = tonumber(parts[2]) or 0;
        state._char_map = state._char_map or {};
        state._char_map[charid] = {
            charid = charid,
            name = parts[3] or '?',
            mjob = tonumber(parts[4]) or 0,
            mlvl = tonumber(parts[5]) or 0,
            sjob = tonumber(parts[6]) or 0,
            slvl = tonumber(parts[7]) or 0,
            flags = tonumber(parts[8]) or 0,
            slot = (channel == 'jobs') and (tonumber(parts[9]) or 0) or (tonumber(parts[11]) or 0),
        };
        return;
    end

    if (kind == 'p' and channel == 'jobs' and (inbound.verb == 'who' or inbound.verb == 'list')) then
        local name = parts[2];
        if (name ~= nil and name ~= '') then
            state.job_presets[#state.job_presets + 1] = name;
        end
        return;
    end

    if (kind == 'f' and channel == 'bags' and inbound.verb == 'find') then
        local charid = tonumber(parts[2]) or 0;
        local loc = tonumber(parts[3]) or 0;
        parse_packed(charid, loc, parts[4], state.finds);
        return;
    end

    if (channel == 'bags' and inbound.verb == 'bag') then
        local charid = tonumber(parts[2]) or 0;
        if (state.bag_charid ~= nil and charid ~= state.bag_charid) then
            return;
        end
        local loc = tonumber(parts[3]) or 0;
        if (kind == 'n') then
            state.bags[loc] = state.bags[loc] or { used = 0, size = 0, items = {} };
            state.bags[loc].used = tonumber(parts[4]) or 0;
            state.bags[loc].size = tonumber(parts[5]) or 0;
            return;
        end
        if (kind == 'i') then
            state.bags[loc] = state.bags[loc] or { used = 0, size = 0, items = {} };
            parse_packed(charid, loc, parts[4], state.bags[loc].items);
            return;
        end
    end
end

local function finish_rules_envelope(verb, records)
    if (verb == 'list' or verb == 'menu') then
        state.rule_sets = {};
    elseif (verb == 'presets') then
        state.rule_presets = {};
    end

    for _, parts in ipairs(records) do
        local kind = parts[1];
        if (kind == 's' and (verb == 'list' or verb == 'menu')) then
            local name = parts[3];
            if (name ~= nil and name ~= '') then
                state.rule_sets[name] = true;
            end
        elseif (kind == 'p' and verb == 'presets') then
            local name = parts[2];
            if (name ~= nil and name ~= '') then
                state.rule_presets[name] = true;
            end
        end
    end
end

local function handle_rules(line)
    local parts = split(line, '|');
    local kind = parts[1];
    local inbound = state.inbound;

    if (kind == 'd') then
        local version = tonumber(parts[2]) or 0;
        if (version ~= PROTOCOL) then
            state.status = string.format('Protocol %d (expected %d) on rules', version, PROTOCOL);
            inbound.channel = nil;
            inbound.verb = nil;
            inbound.buffer = nil;
            return;
        end
        inbound.channel = 'rules';
        inbound.verb = parts[3];
        inbound.buffer = {};
        return;
    end

    if (kind == 'm' or kind == 'e') then
        state.status = line:sub(3);
        return;
    end

    if (inbound.channel ~= 'rules' or inbound.verb == nil) then
        return;
    end

    if (kind == 'z') then
        local verb = inbound.verb;
        local buffer = inbound.buffer or {};
        inbound.channel = nil;
        inbound.verb = nil;
        inbound.buffer = nil;
        finish_rules_envelope(verb, buffer);
        return;
    end

    inbound.buffer[#inbound.buffer + 1] = parts;
end

--- Apply one machine-channel line (sender name + payload).
function M.handle_machine(sender, message)
    local channel = SENDERS[sender];
    if (channel == nil or message == nil or message == '') then
        return false;
    end
    if (channel == 'rules') then
        handle_rules(message);
    else
        handle_squad_or_bags_or_jobs(channel, message);
    end
    return true;
end

--- Parse a human !port list chat line into a destination row when expecting.
-- Matches forms like: `* 1 Southern San d'Oria` or `2. Bastok Mines`
function M.handle_port_line(message)
    if (not state.port_expecting or message == nil) then
        return false;
    end
    local line = message:gsub('%z.*$', ''):gsub('^%s+', ''):gsub('%s+$', '');
    if (line == '') then
        return false;
    end
    local star, num, name = line:match('^(%*?)%s*(%d+)[%.:%)%s]+(.+)$');
    if (num == nil) then
        return false;
    end
    local usable = (star == '*');
    state.port_dests[#state.port_dests + 1] = {
        id = num,
        label = string.format('%s%s %s', usable and '* ' or '', num, name),
        name = name,
        usable = usable,
    };
    return true;
end

local function is_self(flags)
    return math.floor((flags or 0) / CHAR_SELF) % 2 == 1;
end

function M.char_labels(opts)
    opts = opts or {};
    local labels = {};
    if (opts.me) then
        labels[#labels + 1] = 'me';
    end
    if (opts.all) then
        labels[#labels + 1] = 'all';
    end
    for _, c in ipairs(state.chars) do
        local name = c.name;
        if (name ~= nil and name ~= '') then
            if (not (opts.exclude_self and is_self(c.flags))) then
                labels[#labels + 1] = name;
            end
        end
    end
    return labels;
end

function M.job_preset_labels()
    local copy = {};
    for i, n in ipairs(state.job_presets) do
        copy[i] = n;
    end
    return copy;
end

function M.rule_set_labels()
    return sorted_names(state.rule_sets);
end

function M.rule_preset_labels()
    return sorted_names(state.rule_presets);
end

function M.find_entries()
    return state.finds;
end

function M.bag_locations()
    local locs = {};
    for loc, bag in pairs(state.bags) do
        local count = #(bag.items or {});
        if (count > 0 or (bag.used or 0) > 0 or (bag.size or 0) > 0) then
            locs[#locs + 1] = {
                loc = loc,
                label = M.LOC_NAMES[loc] or ('Bag ' .. tostring(loc)),
                used = bag.used or 0,
                size = bag.size or 0,
                count = count,
            };
        end
    end
    table.sort(locs, function(a, b)
        return a.loc < b.loc;
    end);
    return locs;
end

function M.bag_items(loc)
    local bag = state.bags[loc];
    if (bag == nil or bag.items == nil) then
        return {};
    end
    return bag.items;
end

function M.bag_owner()
    return state.bag_charname, state.bag_charid;
end

function M.port_entries()
    return state.port_dests;
end

function M.begin_port_list(tab)
    state.port_tab = tab;
    state.port_dests = {};
    state.port_expecting = true;
end

function M.end_port_list()
    state.port_expecting = false;
end

--- Request helpers (enqueue is ctx.enqueue / queue).
function M.request_roster(enqueue)
    if (enqueue ~= nil) then
        enqueue('!dws who');
    end
end

function M.request_jobs(enqueue)
    if (enqueue ~= nil) then
        enqueue('!dwj who');
    end
end

function M.request_job_presets(enqueue)
    if (enqueue ~= nil) then
        enqueue('!dwj list');
    end
end

function M.request_find(enqueue, text)
    if (enqueue ~= nil and text ~= nil and text ~= '') then
        enqueue(string.format('!dwq find %s', text));
    end
end

function M.request_bag(enqueue, charname)
    if (enqueue == nil or charname == nil or charname == '') then
        return;
    end
    local charid = nil;
    for _, c in ipairs(state.chars) do
        if (c.name == charname) then
            charid = c.charid;
            break;
        end
    end
    -- 'me' → prefer CHAR_SELF from roster
    if (charname == 'me') then
        for _, c in ipairs(state.chars) do
            if (math.floor((c.flags or 0) / CHAR_SELF) % 2 == 1) then
                charid = c.charid;
                charname = c.name;
                break;
            end
        end
    end
    state.bag_charid = charid;
    state.bag_charname = charname;
    state.bags = {};
    enqueue(string.format('!dwq bag %s', charname));
end

function M.request_rule_sets(enqueue)
    if (enqueue ~= nil) then
        enqueue('!dwg list');
    end
end

function M.request_rule_presets(enqueue)
    if (enqueue ~= nil) then
        enqueue('!dwg presets');
    end
end

function M.request_port_list(enqueue, tab, page)
    M.begin_port_list(tab);
    if (enqueue ~= nil) then
        if (page ~= nil) then
            enqueue(string.format('!port list %s %d', tab, page));
        else
            enqueue(string.format('!port list %s', tab));
        end
    end
end

--- Wire Ashita packet_in (observe only — do not block machine senders).
function M.attach()
    if (attached or ashita == nil) then
        return;
    end
    attached = true;
    ashita.events.register('packet_in', 'dwhub_data_packet', function(e)
        if (e.id ~= 0x0017) then
            return;
        end
        local sender = e.data_modified:sub(0x09, 0x17):gsub('%z.*$', '');
        local message = e.data_modified:sub(0x18, e.size):gsub('%z.*$', '');
        if (SENDERS[sender] ~= nil) then
            local ok, err = pcall(M.handle_machine, sender, message);
            if (not ok) then
                state.status = 'parse error: ' .. tostring(err);
            end
            return;
        end
        if (state.port_expecting) then
            pcall(M.handle_port_line, message);
        end
    end);
end

function M.detach()
    -- Ashita has no reliable unregister; leave handler no-op via flag if needed.
    attached = false;
end

-- Exported for tests
M._split = split;
M._parse_packed = parse_packed;
M._PROTOCOL = PROTOCOL;
M._CHAR_SELF = CHAR_SELF;

return M;
