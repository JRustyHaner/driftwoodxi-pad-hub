package.path = 'addons/dwhub/?.lua;' .. package.path;

local cmds = require('cmds');

describe('cmds expansion stubs', function()
    it('builds warehouse and market summaries', function()
        assert.equals('!warehouse', cmds.warehouse_summary());
        assert.equals('!market', cmds.market_summary());
    end);

    it('builds merc and tracker commands', function()
        assert.equals('!merc board', cmds.merc_board());
        assert.equals('!dwt sync', cmds.tracker_sync());
    end);

    it('builds drift, fish, raid, and arena boards', function()
        assert.equals('!drift', cmds.drift_board());
        assert.equals('!fish', cmds.fish_status());
        assert.equals('!raid', cmds.raid_board());
        assert.equals('!arena', cmds.arena_board());
    end);

    it('builds scan and trustengage commands', function()
        assert.equals('!scan', cmds.scan_target());
        assert.equals('!scan 0 8', cmds.scan_target(8));
        assert.equals('!trustengage', cmds.trustengage_status());
        assert.equals('!trustengage 1', cmds.trustengage_mode(1));
    end);
end);
