--[[
* DriftwoodXI Pad Hub — command queue
*
* Outgoing ! / chat lines are rate-limited like official dw* addons: the client
* chat throttle drops bursts, so we send at most one command per INTERVAL.
*
* Pure module: inject send_fn and clock_fn for busted (no Ashita required).
*
* Dedupe: identical command already waiting in the queue is not appended again.
* clear() empties the queue (call when the hub closes if desired).
--]]

local M = {};

-- Seconds between drains (dwbags-class pacing).
M.INTERVAL = 1.2;

local function default_clock()
    return os.clock();
end

--- Create a queue.
--- @param opts table|nil { send_fn = function(cmd), clock_fn = function() -> number, interval = number }
function M.new(opts)
    opts = opts or {};
    local q = {
        _items = {},
        _last_sent = nil,
        _send = opts.send_fn,
        _clock = opts.clock_fn or default_clock,
        interval = opts.interval or M.INTERVAL,
    };

    function q:enqueue(command)
        if (type(command) ~= 'string' or command == '') then
            return false;
        end
        for i = 1, #self._items do
            if (self._items[i] == command) then
                return false;
            end
        end
        self._items[#self._items + 1] = command;
        return true;
    end

    function q:len()
        return #self._items;
    end

    function q:clear()
        self._items = {};
    end

    function q:peek()
        return self._items[1];
    end

    --- Drain at most one command if interval elapsed. Returns command sent or nil.
    function q:tick()
        if (#self._items == 0) then
            return nil;
        end
        if (self._send == nil) then
            return nil;
        end
        local now = self._clock();
        if (self._last_sent ~= nil and (now - self._last_sent) < self.interval) then
            return nil;
        end
        local cmd = table.remove(self._items, 1);
        self._last_sent = now;
        self._send(cmd);
        return cmd;
    end

    function q:set_send(fn)
        self._send = fn;
    end

    return q;
end

return M;
