--[[
* DriftwoodXI Pad Hub — nav stack
*
* Screens are tables: { id, title, description_for(index), rows(), on_confirm(index), on_back? }
* rows() returns { { label, dim?, desc? }, ... }
* Pure enough to unit-test focus movement without ImGui.
--]]

local M = {};

function M.new()
    local n = {
        stack = {},
        focus = 1,
        status = '',
    };

    function n:push(screen)
        self.stack[#self.stack + 1] = screen;
        self.focus = 1;
    end

    function n:pop()
        if (#self.stack <= 1) then
            return false;
        end
        self.stack[#self.stack] = nil;
        self.focus = 1;
        return true;
    end

    function n:current()
        return self.stack[#self.stack];
    end

    function n:depth()
        return #self.stack;
    end

    function n:row_count()
        local s = self:current();
        if (s == nil or s.rows == nil) then
            return 0;
        end
        return #s:rows();
    end

    function n:move(delta)
        local count = self:row_count();
        if (count <= 0) then
            self.focus = 1;
            return;
        end
        local f = self.focus + delta;
        if (f < 1) then
            f = count;
        elseif (f > count) then
            f = 1;
        end
        self.focus = f;
    end

    function n:confirm()
        local s = self:current();
        if (s == nil or s.on_confirm == nil) then
            return;
        end
        s:on_confirm(self.focus, self);
    end

    function n:back()
        local s = self:current();
        if (s ~= nil and s.on_back ~= nil) then
            return s:on_back(self);
        end
        return self:pop();
    end

    function n:focused_row()
        local s = self:current();
        if (s == nil) then
            return nil;
        end
        local rows = s:rows();
        return rows[self.focus];
    end

    function n:description()
        local s = self:current();
        if (s == nil) then
            return '';
        end
        if (s.description_for ~= nil) then
            return s:description_for(self.focus) or '';
        end
        local row = self:focused_row();
        if (row ~= nil and row.desc ~= nil) then
            return row.desc;
        end
        return s.title or '';
    end

    function n:reset(root)
        self.stack = {};
        self.focus = 1;
        self.status = '';
        if (root ~= nil) then
            self:push(root);
        end
    end

    return n;
end

return M;
