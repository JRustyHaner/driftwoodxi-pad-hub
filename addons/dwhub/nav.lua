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
        _list_page = 1,
        _page_size = 8,
    };

    function n:push(screen)
        self.stack[#self.stack + 1] = screen;
        self.focus = 1;
        self._list_page = 1;
    end

    function n:pop()
        if (#self.stack <= 1) then
            return false;
        end
        self.stack[#self.stack] = nil;
        self.focus = 1;
        self._list_page = 1;
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

    function n:page_size()
        return self._page_size or 8;
    end

    function n:set_page_size(size)
        local nsize = tonumber(size) or 8;
        if (nsize < 1) then
            nsize = 1;
        end
        self._page_size = nsize;
    end

    function n:list_page()
        return self._list_page or 1;
    end

    function n:page_count()
        local count = self:row_count();
        if (count <= 0) then
            return 1;
        end
        return math.ceil(count / self:page_size());
    end

    function n:set_list_page(page)
        local pages = self:page_count();
        local p = tonumber(page) or 1;
        if (p < 1) then
            p = 1;
        elseif (p > pages) then
            p = pages;
        end
        self._list_page = p;
    end

    function n:page_row_range()
        local ps = self:page_size();
        local page = self:list_page();
        local count = self:row_count();
        local start_i = (page - 1) * ps + 1;
        local stop_i = math.min(count, page * ps);
        if (count <= 0) then
            start_i = 1;
            stop_i = 0;
        end
        return start_i, stop_i;
    end

    function n:ensure_focus_visible()
        local count = self:row_count();
        if (count <= 0) then
            self.focus = 1;
            self._list_page = 1;
            return;
        end
        if (self.focus < 1) then
            self.focus = 1;
        elseif (self.focus > count) then
            self.focus = count;
        end
        self:set_list_page(math.ceil(self.focus / self:page_size()));
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
        self:ensure_focus_visible();
    end

    function n:move_page(delta)
        if (delta == 0) then
            return;
        end
        local count = self:row_count();
        if (count <= 0) then
            self._list_page = 1;
            self.focus = 1;
            return;
        end
        self:set_list_page(self:list_page() + delta);
        local start_i = (self:list_page() - 1) * self:page_size() + 1;
        self.focus = start_i;
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
        self._list_page = 1;
        if (root ~= nil) then
            self:push(root);
        end
    end

    return n;
end

return M;
