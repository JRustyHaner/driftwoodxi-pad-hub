package.path = 'addons/dwhub/?.lua;' .. package.path;

local layout = require('layout');

describe('layout', function()
    it('fits rows into a pixel budget', function()
        assert.equals(8, layout.page_size_for_height(144, 18));
        assert.equals(1, layout.page_size_for_height(10, 18));
    end);

    it('reserves chrome below the list viewport', function()
        local list_h, page_size = layout.split_list_budget(200, 20, {
            footer_lines = 1,
            page_indicator = true,
            extra_chrome = 8,
        });
        assert.equals(7, page_size);
        assert.equals(140, list_h);
    end);
end);
