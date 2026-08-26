--[[
* Screen factory helpers and Home / placeholder screens.
--]]

local M = {};

function M.placeholder(title, blurb)
    return {
        id = 'placeholder:' .. title,
        title = title,
        rows = function()
            return {
                { label = '(Coming in a follow-up PR)', dim = true, desc = blurb or 'Not implemented yet.' },
            };
        end,
        on_confirm = function() end,
    };
end

function M.home(nav, open_category)
    return {
        id = 'home',
        title = 'Pad Hub',
        rows = function()
            return {
                { label = 'Squad', desc = 'Call, dismiss, slots, field orders, behavior.' },
                { label = 'Jobs', desc = 'Change main/sub jobs or use lineup presets.' },
                { label = 'Items', desc = 'Find, send, fetch, and equip across your account.' },
                { label = 'Rules', desc = 'Assign gambit presets to squad members.' },
                { label = 'Port', desc = 'Home points, guides, outposts, teleport spells.' },
            };
        end,
        on_confirm = function(self, index, n)
            local row = self:rows()[index];
            if (row == nil) then
                return;
            end
            if (open_category ~= nil) then
                open_category(row.label, n);
            else
                n:push(M.placeholder(row.label, row.desc));
            end
        end,
        on_back = function(self, n)
            -- Signal hub to close
            return 'close';
        end,
    };
end

return M;
