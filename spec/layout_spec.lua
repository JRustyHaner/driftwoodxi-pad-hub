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

    it('accounts for filter, description, status, and footer in full frame budget', function()
        local lh = 20;
        local scale = 1.0;
        local chrome_top = layout.chrome_above(lh, scale, {
            has_filter = true,
            desc_lines = 2,
            has_status = true,
        });
        local chrome_bottom = layout.footer_height(lh, {
            footer_lines = 1,
            page_indicator = true,
            separators = 1,
            extra_chrome = 4,
        });
        -- 520×400 window inner ~380px at scale 1 with padding
        local content_h = 380;
        local list_h, page_size = layout.split_content_budget(content_h, lh, chrome_top, chrome_bottom);
        assert.is_true(page_size >= 1);
        assert.equals(page_size, layout.page_size_for_height(list_h, lh));
        assert.equals(list_h, layout.list_height_for_rows(page_size, lh));
        assert.is_true(list_h + chrome_top + chrome_bottom <= content_h + lh);
    end);

    it('includes status line in description chrome', function()
        local lh = 18;
        local base = layout.desc_height(lh, 1.0, { desc_lines = 2, has_status = false });
        local with_status = layout.desc_height(lh, 1.0, { desc_lines = 2, has_status = true });
        assert.equals(lh, with_status - base);
    end);
end);
